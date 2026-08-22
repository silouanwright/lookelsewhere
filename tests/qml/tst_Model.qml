import QtQuick
import QtTest
import "../../Model.js" as Model

TestCase {
  name: "LookElsewhereModel"

  function config(overrides) {
    var value = { focusMs: 60000, breakMs: 5000, dueSoonMs: 2000, warningMs: 4000, finalMs: 1000, cooldownMs: 2000, maximumDelayMs: 10000 }
    for (var key in (overrides || {})) value[key] = overrides[key]
    return Model.normalizeConfig(value)
  }

  function test_overnightOfficeHours() {
    var hours = { enabled: true, startMinute: 20 * 60, endMinute: 2 * 60 }
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 23, 0), hours))
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 1, 0), hours))
    verify(!Model.inOfficeHours(new Date(2026, 7, 22, 12, 0), hours))
  }

  function test_officeHourBoundaries() {
    var daytime = { enabled: true, startMinute: 8 * 60, endMinute: 18 * 60 }
    verify(!Model.inOfficeHours(new Date(2026, 7, 22, 7, 59), daytime))
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 8, 0), daytime))
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 17, 59), daytime))
    verify(!Model.inOfficeHours(new Date(2026, 7, 22, 18, 0), daytime))

    // Equal bounds intentionally mean an all-day schedule rather than a
    // zero-length schedule.
    var allDay = { enabled: true, startMinute: 0, endMinute: 0 }
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 12, 0), allDay))
  }

  function test_settingsRebuildFromDefaults() {
    var customized = Model.configFromSettings({
      focusMinutes: 25,
      breakTitle: "Rest your eyes",
      breakSubtitle: "Look across the room.",
      officeHoursEnabled: true,
      officeStart: "22:30",
      mediaDetection: false,
      soundEnabled: true,
      soundVolume: 35,
      startSoundEnabled: false,
      completionSoundPath: "~/Sounds/done.ogg",
      outputMode: "focused"
    })
    compare(customized.focusMs, 25 * 60000)
    compare(customized.breakTitle, "Rest your eyes")
    compare(customized.breakSubtitle, "Look across the room.")
    verify(customized.officeHours.enabled)
    compare(customized.officeHours.startMinute, 22 * 60 + 30)
    verify(!customized.detectors.media)
    verify(customized.soundEnabled)
    compare(customized.soundVolume, 35)
    verify(!customized.startSoundEnabled)
    compare(customized.completionSoundPath, "~/Sounds/done.ogg")
    compare(customized.outputMode, "focused")

    // Omarchy supplies no key after an override is removed. A fresh
    // reconciliation must restore defaults rather than retain old config.
    var restored = Model.configFromSettings({})
    compare(restored.focusMs, 20 * 60000)
    verify(!restored.officeHours.enabled)
    compare(restored.officeHours.startMinute, 8 * 60)
    verify(restored.detectors.media)
    verify(restored.soundEnabled)
    compare(restored.soundVolume, 65)
    verify(restored.startSoundEnabled)
    verify(restored.completionSoundEnabled)
    compare(restored.startSoundPath, "")
    compare(restored.completionSoundPath, "")
    compare(restored.outputMode, "all")
  }

  function test_settingsNormalizeInvalidValues() {
    var value = Model.configFromSettings({
      focusMinutes: "not-a-number",
      breakSeconds: 99999,
      enforcement: "unknown",
      officeStart: "25:90"
    })
    compare(value.focusMs, 20 * 60000)
    compare(value.breakMs, 60 * 60 * 1000)
    compare(value.enforcement, "balanced")
    compare(value.officeHours.startMinute, 8 * 60)
  }

  function test_activeUseDoesNotCountIdle() {
    var c = config()
    var s = Model.defaultSnapshot(1000)
    s = Model.observe(s, { nowMs: 6000, active: true, idle: true, evidence: [] }, c)
    compare(s.accumulatedActiveMs, 0)
    s = Model.observe(s, { nowMs: 11000, active: true, idle: false, evidence: [] }, c)
    compare(s.accumulatedActiveMs, 5000)
  }

  function test_dueFlowAndProtection() {
    var c = config()
    var s = Model.defaultSnapshot(1000)
    s = Model.observe(s, { nowMs: 61000, active: true, idle: false, evidence: [{ category: "meeting", active: true, confidence: 0.9 }] }, c)
    compare(s.state, Model.State.Protected)
    compare(s.protectedCategory, "meeting")
    s = Model.observe(s, { nowMs: 62000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Waiting)
    s = Model.observe(s, { nowMs: 65000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Warning)
  }

  function test_warningOccupiesFinalFocusSeconds() {
    var c = config({ focusMs: 60000, warningMs: 25000, finalMs: 3000 })
    var s = Model.defaultSnapshot(1000)

    s = Model.observe(s, {
      nowMs: 36000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Warning)
    compare(s.warningEndsAtMs, 61000)
    compare(s.totals.prompted, 1)

    s = Model.observe(s, {
      nowMs: 58000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Final)

    s = Model.observe(s, {
      nowMs: 61000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Breaking)
    compare(s.totals.prompted, 1)
  }

  function test_dueBreakWaitsForNaturalPause() {
    var c = config({ maximumDelayMs: 10000 })
    var s = Model.defaultSnapshot(0)
    s.accumulatedActiveMs = c.focusMs

    s = Model.observe(s, {
      nowMs: 1000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Waiting)
    compare(s.dueAtMs, 1000)
    compare(s.totals.prompted, 0)

    s = Model.observe(s, {
      nowMs: 4000, active: true, idle: false, naturalPause: true, evidence: []
    }, c)
    compare(s.state, Model.State.Warning)
    compare(s.totals.prompted, 1)
  }

  function test_naturalPauseCannotExceedMaximumDelay() {
    var c = config({ maximumDelayMs: 5000 })
    var s = Model.defaultSnapshot(0)
    s.accumulatedActiveMs = c.focusMs
    s.dueAtMs = 1000
    s = Model.observe(s, {
      nowMs: 5999, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Waiting)
    s = Model.observe(s, {
      nowMs: 6000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Warning)
  }

  function test_maximumDelayOverridesProtection() {
    var c = config({ maximumDelayMs: 5000 })
    var s = Model.defaultSnapshot(0)
    s.accumulatedActiveMs = c.focusMs
    s.dueAtMs = 1000
    s = Model.observe(s, { nowMs: 7000, active: true, idle: false, evidence: [{ category: "meeting", active: true, confidence: 1 }] }, c)
    compare(s.state, Model.State.Warning)
  }

  function test_clockRollbackDoesNotSubtractActiveUse() {
    var c = config()
    var s = Model.defaultSnapshot(10000)
    s.accumulatedActiveMs = 5000
    s = Model.observe(s, { nowMs: 5000, active: true, idle: false, evidence: [] }, c)
    compare(s.accumulatedActiveMs, 5000)
  }

  function test_longSuspendDoesNotCountAsActiveUse() {
    var c = config({ focusMs: 60 * 60 * 1000 })
    var s = Model.defaultSnapshot(1000)
    s = Model.observe(s, { nowMs: 8 * 60 * 60 * 1000, active: true, idle: false, evidence: [] }, c)
    // A missing observation is capped so suspend, hibernate, and clock jumps
    // cannot manufacture an entire focus session.
    compare(s.accumulatedActiveMs, 5 * 60 * 1000)
  }

  function test_outsideOfficeHoursPausesAndReentersCleanly() {
    var c = config({ officeHours: { enabled: true, startMinute: 8 * 60, endMinute: 18 * 60 } })
    var beforeOpen = new Date(2026, 7, 22, 7, 59).getTime()
    var atOpen = new Date(2026, 7, 22, 8, 0).getTime()
    var s = Model.defaultSnapshot(beforeOpen - 1000)
    s.accumulatedActiveMs = 10000
    s = Model.observe(s, { nowMs: beforeOpen, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Paused)
    compare(s.pauseReason, "outside-office-hours")
    compare(s.accumulatedActiveMs, 10000)
    s = Model.observe(s, { nowMs: atOpen, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Working)
    compare(s.pauseReason, "")
    compare(s.accumulatedActiveMs, 10000)
  }

  function test_warningFinalBreakCompletion() {
    var c = config()
    var s = Model.defaultSnapshot(0)
    s.accumulatedActiveMs = c.focusMs
    s = Model.observe(s, { nowMs: 1000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Warning)
    s = Model.observe(s, { nowMs: 4000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Final)
    s = Model.observe(s, { nowMs: 5000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Breaking)
    s = Model.observe(s, { nowMs: 10000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Working)
    compare(s.totals.completed, 1)
  }

  function test_periodicLongBreak() {
    var c = config({ breakMs: 5000, longBreakEvery: 4, longBreakMs: 180000 })
    var s = Model.defaultSnapshot(1000)
    s.totals.completed = 2
    s.totals.skipped = 1
    s = Model.startBreak(s, 1000, c)
    compare(s.activeBreakDurationMs, 180000)
    compare(s.breakEndsAtMs, 181000)

    s = Model.defaultSnapshot(1000)
    s.totals.completed = 1
    s = Model.startBreak(s, 1000, c)
    compare(s.activeBreakDurationMs, 5000)
    compare(s.breakEndsAtMs, 6000)

    c.longBreakEvery = 0
    s.totals.completed = 3
    s = Model.startBreak(s, 1000, c)
    compare(s.activeBreakDurationMs, 5000)
  }

  function test_restartReconcilesExpiredBreakWithoutDuplication() {
    var c = config()
    var persisted = Model.defaultSnapshot(1000)
    persisted.state = Model.State.Breaking
    persisted.breakEndsAtMs = 5000
    persisted.totals.prompted = 1

    var recovered = Model.observe(Model.copySnapshot(persisted), {
      nowMs: 10000, active: false, idle: false, evidence: []
    }, c)
    compare(recovered.state, Model.State.Working)
    compare(recovered.totals.completed, 1)

    // Re-observing the recovered snapshot must not duplicate the outcome.
    recovered = Model.observe(recovered, {
      nowMs: 11000, active: false, idle: false, evidence: []
    }, c)
    compare(recovered.totals.completed, 1)
  }

  function test_restartAdvancesExpiredWarningDeterministically() {
    var c = config()
    var persisted = Model.defaultSnapshot(1000)
    persisted.state = Model.State.Warning
    persisted.warningEndsAtMs = 5000
    persisted.totals.prompted = 1

    var recovered = Model.observe(persisted, {
      nowMs: 10000, active: false, idle: false, evidence: []
    }, c)
    compare(recovered.state, Model.State.Final)
    recovered = Model.observe(recovered, {
      nowMs: 10001, active: false, idle: false, evidence: []
    }, c)
    compare(recovered.state, Model.State.Breaking)
    compare(recovered.totals.prompted, 1)
  }

  function test_postpone() {
    var s = Model.defaultSnapshot(0)
    s.state = Model.State.Warning
    s = Model.postpone(s, 1000, 60000, config())
    compare(s.state, Model.State.Waiting)
    compare(s.postponedUntilMs, 61000)
    compare(s.snoozesUsed, 1)
    compare(s.totals.postponed, 1)
  }

  function test_delayNextBreakAddsTimeDuringOrdinaryFocus() {
    var c = config({ focusMs: 20 * 60000 })
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 60 * 1000
    s.state = Model.State.Working

    s = Model.delayNextBreak(s, 2000, 60 * 1000, c)

    compare(s.state, Model.State.Working)
    compare(c.focusMs - s.accumulatedActiveMs, 20 * 60000)
    compare(s.lastObservedAtMs, 2000)
    compare(s.snoozesUsed, 1)
    compare(s.totals.postponed, 1)
  }

  function test_delayNextBreakPreservesDuePostponeSemantics() {
    var s = Model.defaultSnapshot(0)
    s.state = Model.State.Warning

    s = Model.delayNextBreak(s, 1000, 60 * 1000, config())

    compare(s.state, Model.State.Waiting)
    compare(s.postponedUntilMs, 61000)
    compare(s.snoozesUsed, 1)
  }

  function test_postponeExpiryReturnsToWarning() {
    var c = config()
    var s = Model.defaultSnapshot(0)
    s.accumulatedActiveMs = c.focusMs
    s.dueAtMs = 1000
    s = Model.postpone(s, 1000, 5000, c)
    s = Model.observe(s, { nowMs: 5999, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Waiting)
    s = Model.observe(s, { nowMs: 6000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Warning)
    compare(s.totals.prompted, 1)
  }

  function test_postponeBudgetAcrossEnforcementModes() {
    var s = Model.defaultSnapshot(0)
    s.state = Model.State.Warning
    s.snoozesUsed = 1
    verify(!Model.canPostpone(s, config({ snoozeBudget: 1 })))
    verify(Model.canPostpone(s, config({ snoozeBudget: 2, enforcement: "hardcore" })))
    verify(Model.canPostpone(s, config({ snoozeBudget: 2, enforcement: "balanced" })))
  }

  function test_hardcoreEnforcementCannotSkipBreak() {
    verify(Model.canSkipBreak(config({ enforcement: "casual" })))
    verify(Model.canSkipBreak(config({ enforcement: "balanced" })))
    verify(!Model.canSkipBreak(config({ enforcement: "hardcore" })))
  }

  function test_legacyEnforcementNamesMigrate() {
    compare(config({ enforcement: "gentle" }).enforcement, "casual")
    compare(config({ enforcement: "focused" }).enforcement, "hardcore")
  }

  function test_soundCuesFollowBreakTransitions() {
    compare(Model.soundCueForTransition(Model.State.Final, Model.State.Breaking), "start")
    compare(Model.soundCueForTransition(Model.State.Working, Model.State.Breaking), "start")
    compare(Model.soundCueForTransition(Model.State.Breaking, Model.State.Working), "complete")
    compare(Model.soundCueForTransition(Model.State.Warning, Model.State.Final), "")
    compare(Model.soundCueForTransition(Model.State.Breaking, Model.State.Breaking), "")
  }

  function test_completionCueLeadsBreakDismissal() {
    verify(!Model.shouldLeadCompletionCue(Model.State.Breaking, 101, 100))
    verify(Model.shouldLeadCompletionCue(Model.State.Breaking, 100, 100))
    verify(Model.shouldLeadCompletionCue(Model.State.Breaking, 1, 100))
    verify(!Model.shouldLeadCompletionCue(Model.State.Breaking, 0, 100))
    verify(!Model.shouldLeadCompletionCue(Model.State.Working, 50, 100))
  }

  function test_resetTotalsPreservesSchedule() {
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 5000
    s.totals = { prompted: 2, completed: 1, postponed: 3, skipped: 4, delayed: 5 }
    var reset = Model.resetTotals(s)
    compare(reset.accumulatedActiveMs, 5000)
    compare(reset.totals.completed, 0)
    compare(reset.totals.delayed, 0)
  }

  function test_evidenceThresholdAndDetectorToggle() {
    var c = config({ detectors: { microphone: true, media: false } })
    compare(Model.strongestEvidence([{ category: "microphone", active: true, confidence: 0.59 }], c), null)
    compare(Model.strongestEvidence([{ category: "media", active: true, confidence: 1 }], c), null)
    compare(Model.strongestEvidence([{ category: "microphone", active: true, confidence: 0.8 }], c).category, "microphone")
  }

  function test_formatting() {
    compare(Model.formatDuration(0), "0s")
    compare(Model.formatDuration(23000), "23s")
    compare(Model.formatDuration(61000), "1m 1s")
    compare(Model.formatDuration(3600000), "1h")
    compare(Model.formatBarDuration(0), "0s")
    compare(Model.formatBarDuration(999), "1s")
    compare(Model.formatBarDuration(59001), "60s")
    compare(Model.formatBarDuration(59000), "59s")
    compare(Model.formatBarDuration(60000), "1m")
    compare(Model.formatBarDuration(60001), "1m")
  }

  function test_protectedExplanationAvoidsInternalLabels() {
    compare(Model.protectedExplanation("meeting"), "Held quietly while your meeting is active.")
    compare(Model.protectedExplanation("dictation"), "Held quietly while dictation is active.")
  }

  function test_manualPauseLabel() {
    var snapshot = Model.defaultSnapshot(0)
    snapshot.state = Model.State.Waiting
    snapshot.pauseReason = "manual"
    compare(Model.stateLabel(snapshot), "Breaks paused")
  }

  function test_workingLabelMatchesPanelLanguage() {
    compare(Model.stateLabel(Model.defaultSnapshot(0)), "Break starts in")
  }

  function test_manualPausePersistsUntilExplicitResume() {
    var c = config()
    var s = Model.defaultSnapshot(1000)
    s.state = Model.State.Waiting
    s.pauseReason = "manual"
    s.accumulatedActiveMs = 12000
    s = Model.observe(s, {
      nowMs: 10 * 60 * 60 * 1000, active: true, idle: false, naturalPause: true, evidence: []
    }, c)
    compare(s.state, Model.State.Waiting)
    compare(s.pauseReason, "manual")
    compare(s.accumulatedActiveMs, 12000)
  }
}

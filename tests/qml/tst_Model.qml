import QtQuick
import QtTest
import "../../Model.js" as Model
import "../../vendor/qmlpack/oma-command-layer/Ui/CommandModel.js" as CommandModel

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
      recentInputDetection: false,
      soundEnabled: true,
      soundVolume: 35,
      startSoundEnabled: false,
      completionSoundPath: "~/Sounds/done.ogg",
      outputMode: "focused",
      panelPattern: "wiggle"
    })
    compare(customized.focusMs, 25 * 60000)
    compare(customized.breakTitle, "Rest your eyes")
    compare(customized.breakSubtitle, "Look across the room.")
    verify(customized.officeHours.enabled)
    compare(customized.officeHours.startMinute, 22 * 60 + 30)
    verify(!customized.detectors.media)
    verify(!customized.detectors.recentInput)
    verify(customized.soundEnabled)
    compare(customized.soundVolume, 35)
    verify(!customized.startSoundEnabled)
    compare(customized.completionSoundPath, "~/Sounds/done.ogg")
    compare(customized.outputMode, "focused")
    compare(customized.panelPattern, "wiggle")
    compare(customized.protectedApps.join(","), "steam")

    // Omarchy supplies no key after an override is removed. A fresh
    // reconciliation must restore defaults rather than retain old config.
    var restored = Model.configFromSettings({})
    compare(restored.focusMs, 20 * 60000)
    verify(!restored.officeHours.enabled)
    compare(restored.officeHours.startMinute, 8 * 60)
    verify(restored.detectors.media)
    verify(restored.detectors.recentInput)
    verify(restored.soundEnabled)
    compare(restored.soundVolume, 65)
    verify(restored.startSoundEnabled)
    verify(restored.completionSoundEnabled)
    compare(restored.startSoundPath, "")
    compare(restored.completionSoundPath, "")
    compare(restored.outputMode, "all")
    compare(restored.panelPattern, "off")
  }

  function test_settingsNormalizeInvalidValues() {
    var value = Model.configFromSettings({
      focusMinutes: "not-a-number",
      breakSeconds: 99999,
      enforcement: "unknown",
      panelPattern: "unknown",
      officeStart: "25:90"
    })
    compare(value.focusMs, 20 * 60000)
    compare(value.breakMs, 60 * 60 * 1000)
    compare(value.panelPattern, "off")
    compare(value.enforcement, "balanced")
    compare(value.officeHours.startMinute, 8 * 60)
  }

  function test_panelShortcutConfiguration() {
    var defaults = CommandModel.resolve({}, Model.panelShortcutDefinitions())
    compare(defaults.breakNow, "B")
    compare(defaults.generalTab, "G")
    compare(defaults.breaksTab, "R")
    compare(defaults.hints, "?")

    var customized = CommandModel.resolve({
      shortcutBreakNow: "ctrl + k",
      shortcutGeneralTab: "F2",
      shortcutHints: "F1"
    }, Model.panelShortcutDefinitions())
    compare(customized.breakNow, "Ctrl+K")
    compare(customized.generalTab, "F2")
    compare(customized.hints, "F1")
    compare(CommandModel.label("Ctrl+K"), "Ctrl+K")
    compare(CommandModel.label("Shift+D"), "⬆D")

    var invalid = CommandModel.resolve({ shortcutBreakNow: "Escape", shortcutPause: "" },
                                       Model.panelShortcutDefinitions())
    compare(invalid.breakNow, "B")
    compare(invalid.pause, "P")

    var duplicate = CommandModel.resolve({ shortcutBreakNow: "H" },
                                         Model.panelShortcutDefinitions())
    compare(duplicate.breakNow, "B")
    compare(duplicate.history, "H")
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

  function test_protectionInterceptsNormalCountdownBeforeWarning() {
    var c = config({ focusMs: 60000, warningMs: 25000, maximumDelayMs: 30000 })
    var s = Model.defaultSnapshot(1000)

    s = Model.observe(s, {
      nowMs: 36000, active: true, idle: false,
      evidence: [{ category: "application", active: true, confidence: 1 }]
    }, c)
    compare(s.state, Model.State.Protected)
    compare(s.protectedCategory, "application")
    compare(s.dueAtMs, 61000)
    compare(s.totals.prompted, 0)

    s = Model.observe(s, {
      nowMs: 61000, active: true, idle: false,
      evidence: [{ category: "application", active: true, confidence: 1 }]
    }, c)
    compare(s.state, Model.State.Protected)
    compare(s.totals.delayed, 1)

    s = Model.observe(s, {
      nowMs: 90999, active: true, idle: false,
      evidence: [{ category: "application", active: true, confidence: 1 }]
    }, c)
    compare(s.state, Model.State.Protected)
    s = Model.observe(s, {
      nowMs: 91000, active: true, idle: false,
      evidence: [{ category: "application", active: true, confidence: 1 }]
    }, c)
    compare(s.state, Model.State.Warning)
  }

  function test_protectionCanCancelAnActiveWarning() {
    var c = config({ focusMs: 60000, warningMs: 25000, maximumDelayMs: 30000 })
    var s = Model.defaultSnapshot(1000)
    s = Model.observe(s, {
      nowMs: 36000, active: true, idle: false, evidence: []
    }, c)
    compare(s.state, Model.State.Warning)

    s = Model.observe(s, {
      nowMs: 40000, active: true, idle: false,
      evidence: [{ category: "application", active: true, confidence: 1 }]
    }, c)
    compare(s.state, Model.State.Protected)
    compare(s.dueAtMs, 61000)
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

  function test_typingHoldsFinalTenSeconds() {
    var c = config({ focusMs: 60000, warningMs: 25000, finalMs: 3000, maximumDelayMs: 30000 })
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 35000
    s = Model.observe(s, { nowMs: 1000, active: true, idle: false, evidence: [] }, c)
    compare(s.warningEndsAtMs, 26000)

    s = Model.observe(s, { nowMs: 17000, typingActive: true, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Warning)
    compare(s.warningEndsAtMs, 27000)

    s = Model.observe(s, { nowMs: 18000, typingActive: false, active: true, idle: false, evidence: [] }, c)
    compare(s.warningEndsAtMs, 27000)
    s = Model.observe(s, { nowMs: 27000, typingActive: false, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Final)
    s = Model.observe(s, { nowMs: 27001, typingActive: false, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Breaking)
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
    s = Model.observe(s, { nowMs: 30 * 60 * 1000, active: true, idle: false, evidence: [] }, c)
    // A meaningful missing interval is classified as time away. Resuming the
    // prior session must not manufacture active screen time.
    compare(s.accumulatedActiveMs, 0)
    compare(s.naturalBreakDecision.kind, "resumed")
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
    s.breaksSinceLong = 3
    verify(Model.isNextBreakLong(s, c))
    s = Model.startBreak(s, 1000, c)
    compare(s.activeBreakDurationMs, 180000)
    verify(s.activeBreakIsLong)
    compare(s.breakEndsAtMs, 181000)
    s = Model.completeBreak(s, 181000)
    compare(s.breaksSinceLong, 0)

    s = Model.defaultSnapshot(1000)
    s.breaksSinceLong = 1
    verify(!Model.isNextBreakLong(s, c))
    s = Model.startBreak(s, 1000, c)
    compare(s.activeBreakDurationMs, 5000)
    verify(!s.activeBreakIsLong)
    compare(s.breakEndsAtMs, 6000)
    s = Model.completeBreak(s, 6000)
    compare(s.breaksSinceLong, 2)

    c.longBreakEvery = 0
    s.breaksSinceLong = 3
    s = Model.startBreak(s, 1000, c)
    compare(s.activeBreakDurationMs, 5000)
  }

  function test_longInactivityStartsFreshBreakCycle() {
    var c = config()
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = c.focusMs - 3 * 60 * 1000
    s.breaksSinceLong = 3
    s.snoozesUsed = 2
    s.totals.completed = 7

    s = Model.observe(s, {
      nowMs: 1000 + 60 * 60 * 1000,
      active: true,
      idle: false,
      evidence: []
    }, c)

    compare(s.state, Model.State.Working)
    compare(s.accumulatedActiveMs, 0)
    compare(s.breaksSinceLong, 0)
    compare(s.snoozesUsed, 0)
    compare(s.totals.completed, 7)
  }

  function test_shortInactivityPreservesBreakCycle() {
    var c = config()
    var s = Model.defaultSnapshot(1000)
    s.breaksSinceLong = 2

    s = Model.observe(s, {
      nowMs: 1000 + 59 * 60 * 1000,
      active: true,
      idle: false,
      evidence: []
    }, c)

    compare(s.breaksSinceLong, 2)
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

  function test_delayNextBreakReschedulesWarningCountdown() {
    var c = config()
    var s = Model.defaultSnapshot(0)
    s.state = Model.State.Warning

    s = Model.delayNextBreak(s, 1000, 60 * 1000, c)

    compare(s.state, Model.State.Working)
    compare(c.focusMs - s.accumulatedActiveMs, 60000)
    compare(s.postponedUntilMs, 0)
    compare(s.snoozesUsed, 1)
  }

  function test_warningSnoozeReturnsAtWarningThreshold() {
    var c = config({ focusMs: 180000, warningMs: 60000, finalMs: 3000 })
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 120000
    s = Model.observe(s, {
      nowMs: 1000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Warning)
    compare(s.warningEndsAtMs, 61000)

    s = Model.delayNextBreak(s, 1000, 60000, c)
    compare(s.state, Model.State.Working)
    compare(c.focusMs - s.accumulatedActiveMs, 120000)

    s = Model.observe(s, {
      nowMs: 60000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Working)
    s = Model.observe(s, {
      nowMs: 61000, active: true, idle: false, naturalPause: false, evidence: []
    }, c)
    compare(s.state, Model.State.Warning)
    compare(s.warningEndsAtMs, 121000)
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

  function test_pausePolicyAllowsCountdownButNotActiveBreak() {
    verify(Model.canTogglePause(Model.State.Working))
    verify(Model.canTogglePause(Model.State.Warning))
    verify(Model.canTogglePause(Model.State.Final))
    verify(!Model.canTogglePause(Model.State.Breaking))
  }

  function test_manualPauseAndResumeTransitions() {
    var original = Model.defaultSnapshot(1000)
    original.accumulatedActiveMs = 42000

    var timed = Model.pause(original, 2000, 60000)
    compare(timed.state, Model.State.Waiting)
    compare(timed.pauseReason, "manual")
    compare(timed.postponedUntilMs, 62000)
    compare(timed.accumulatedActiveMs, 42000)
    compare(original.state, Model.State.Working)

    var indefinite = Model.pause(timed, 3000, 0)
    compare(indefinite.postponedUntilMs, 0)

    var resumed = Model.resume(indefinite, 4000)
    compare(resumed.state, Model.State.Working)
    compare(resumed.pauseReason, "")
    compare(resumed.postponedUntilMs, 0)
    compare(resumed.lastObservedAtMs, 4000)
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
    verify(!Model.shouldLeadCompletionCue(Model.State.Breaking, 26, 25))
    verify(Model.shouldLeadCompletionCue(Model.State.Breaking, 25, 25))
    verify(Model.shouldLeadCompletionCue(Model.State.Breaking, 1, 25))
    verify(!Model.shouldLeadCompletionCue(Model.State.Breaking, 0, 25))
    verify(!Model.shouldLeadCompletionCue(Model.State.Working, 10, 25))
  }

  function test_resetTotalsPreservesSchedule() {
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 5000
    s.totals = { prompted: 2, completed: 1, postponed: 3, skipped: 4, delayed: 5 }
    s.breaksSinceLong = 2
    var reset = Model.resetTotals(s)
    compare(reset.accumulatedActiveMs, 5000)
    compare(reset.breaksSinceLong, 2)
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

  function test_contextShortLabels() {
    compare(Model.contextShortLabel("dictation"), "Dictation")
    compare(Model.contextShortLabel("meeting"), "Meeting")
    compare(Model.contextShortLabel("microphone"), "Mic")
    compare(Model.contextShortLabel("video"), "Video")
    compare(Model.contextShortLabel("media"), "Media")
    compare(Model.contextShortLabel("fullscreen"), "Fullscreen")
    compare(Model.contextShortLabel("unknown"), "")
  }

  function test_mprisPlayerMustMatchFocusedApp() {
    verify(Model.appIdsMatch("chromium.desktop", "chromium"))
    verify(Model.appIdsMatch("firefox.instance123", "firefox"))
    verify(!Model.appIdsMatch("spotify", "foot"))
    verify(!Model.appIdsMatch("", "chromium"))
  }

  function test_pipewireRoleEvidenceIsExplicitAndPrivacyPreserving() {
    compare(Model.pipewireRoleEvidence({ role: "screen" }, false).category, "screen-sharing")
    compare(Model.pipewireRoleEvidence({ role: "communication" }, false).category, "meeting")
    compare(Model.pipewireRoleEvidence({ role: "camera" }, false).category, "camera")
    compare(Model.pipewireRoleEvidence({ role: "movie" }, true).category, "video")
    compare(Model.pipewireRoleEvidence({ role: "movie" }, false), null)
    compare(Model.pipewireRoleEvidence({ role: "", captureAudio: true }, false).category, "microphone")
    compare(Model.pipewireRoleEvidence({ role: "" }, true), null)
    verify(Model.pipewireNodeMatchesApp({ applications: ["chromium"] }, "chromium"))
    verify(!Model.pipewireNodeMatchesApp({ applications: ["Music Player"] }, "chromium"))

    var config = Model.defaultConfig()
    compare(Model.strongestEvidence([
      Model.pipewireRoleEvidence({ role: "screen" }, false),
      Model.pipewireRoleEvidence({ role: "communication" }, false)
    ], config).category, "screen-sharing")
    config.detectors.screenSharing = false
    compare(Model.strongestEvidence([
      Model.pipewireRoleEvidence({ role: "screen" }, false),
      Model.pipewireRoleEvidence({ role: "communication" }, false)
    ], config).category, "meeting")
  }

  function test_protectedApplicationsDefaultToSteam() {
    var defaults = Model.configFromSettings({})
    compare(defaults.protectedApps.join(","), "steam")
    verify(Model.matchesProtectedApp("steam", defaults.protectedApps))
    verify(Model.matchesProtectedApp("steam_app_1868140", defaults.protectedApps))
    verify(!Model.matchesProtectedApp("chromium", defaults.protectedApps))

    var customized = Model.configFromSettings({ protectedApps: "code, org.gnome.Builder.desktop" })
    compare(customized.protectedApps.join(","), "code,org.gnome.builder")
    verify(Model.matchesProtectedApp("org.gnome.Builder", customized.protectedApps))
    compare(Model.toggleProtectedApp(defaults.protectedApps, "steam_app_1868140"), "")
    compare(Model.toggleProtectedApp(defaults.protectedApps, "ORG.GNOME.Builder.desktop"), "steam, org.gnome.builder")
    compare(Model.toggleProtectedApp(["steam", "org.gnome.builder"], "org.gnome.Builder"), "steam")
    compare(Model.toggleProtectedApp(defaults.protectedApps, ""), "steam")
  }

  function test_manualPauseLabel() {
    var snapshot = Model.defaultSnapshot(0)
    snapshot.state = Model.State.Waiting
    snapshot.pauseReason = "manual"
    compare(Model.stateLabel(snapshot), "Breaks paused")
  }

  function test_copySnapshot_rejects_invalid_persisted_values() {
    var snapshot = Model.copySnapshot({
      version: 99,
      state: "surprise",
      accumulatedActiveMs: "1e999",
      snoozesUsed: -4,
      totals: { completed: "nope" }
    })
    compare(snapshot.version, 1)
    compare(snapshot.state, Model.State.Working)
    compare(snapshot.accumulatedActiveMs, 0)
    compare(snapshot.snoozesUsed, 0)
    compare(snapshot.totals.completed, 0)
  }

  function test_recoverSnapshot_rejects_implausible_future_deadline() {
    var now = 1000000
    var snapshot = Model.defaultSnapshot(now)
    snapshot.state = Model.State.Breaking
    snapshot.breakEndsAtMs = 1e308
    compare(Model.recoverSnapshot(snapshot, now), null)

    snapshot.breakEndsAtMs = now + 60000
    verify(Model.recoverSnapshot(snapshot, now) !== null)
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

  function test_naturalBreakResumesAfterMeaningfulAwayTime() {
    var c = config({ focusMs: 30 * 60 * 1000 })
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 8 * 60 * 1000
    s.statistics.currentSessionActiveMs = 8 * 60 * 1000
    s.lastActiveAtMs = 1000
    s.lastObservedAtMs = 10 * 60 * 1000
    s = Model.observe(s, { nowMs: 10 * 60 * 1000 + 1000, active: true, idle: false, evidence: [] }, c)
    compare(s.naturalBreakDecision.kind, "resumed")
    compare(s.accumulatedActiveMs, 8 * 60 * 1000)
    verify(Model.naturalBreakMessage(s).indexOf("Timer resumed") === 0)
  }

  function test_naturalBreakResetCanBeUndone() {
    var c = config({ focusMs: 30 * 60 * 1000 })
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 8 * 60 * 1000
    s.statistics.currentSessionActiveMs = 8 * 60 * 1000
    s.breaksSinceLong = 3
    s.snoozesUsed = 2
    s.lastActiveAtMs = 1000
    s.lastObservedAtMs = 2 * 60 * 60 * 1000
    s = Model.observe(s, { nowMs: 2 * 60 * 60 * 1000 + 1000, active: true, idle: false, evidence: [] }, c)
    compare(s.naturalBreakDecision.kind, "reset")
    compare(s.accumulatedActiveMs, 0)
    compare(s.statistics.today.sessions.length, 1)
    compare(s.statistics.today.sessions[0].outcome, "away")
    s = Model.undoNaturalBreak(s, 2 * 60 * 60 * 1000 + 2000)
    compare(s.accumulatedActiveMs, 8 * 60 * 1000)
    compare(s.breaksSinceLong, 3)
    compare(s.snoozesUsed, 2)
    compare(s.statistics.currentSessionActiveMs, 8 * 60 * 1000)
    compare(s.statistics.today.sessions.length, 0)
    compare(s.naturalBreakDecision, null)
  }

  function test_undoResumeStartsFreshSession() {
    var c = config({ focusMs: 30 * 60 * 1000 })
    var s = Model.defaultSnapshot(1000)
    s.accumulatedActiveMs = 8 * 60 * 1000
    s.lastActiveAtMs = 1000
    s.lastObservedAtMs = 10 * 60 * 1000
    s = Model.observe(s, { nowMs: 10 * 60 * 1000 + 1000, active: true, idle: false, evidence: [] }, c)
    s = Model.undoNaturalBreak(s, 10 * 60 * 1000 + 2000)
    compare(s.accumulatedActiveMs, 0)
    compare(s.naturalBreakDecision, null)
  }

  function test_naturalBreakDecisionSurvivesSafeRecovery() {
    var now = 10 * 60 * 1000
    var s = Model.defaultSnapshot(1000)
    s.naturalBreakDecision = {
      kind: "reset", awayMs: now, decidedAtMs: now, undoUntilMs: now + 60000,
      before: { state: Model.State.Working, accumulatedActiveMs: 12000, breaksSinceLong: 2, snoozesUsed: 1 }
    }
    var recovered = Model.recoverSnapshot(s, now)
    compare(recovered.naturalBreakDecision.kind, "reset")
    compare(recovered.naturalBreakDecision.before.accumulatedActiveMs, 12000)
  }

  function test_statisticsCountOnlyActiveScreenTime() {
    var c = config()
    var s = Model.defaultSnapshot(1000)
    s = Model.observe(s, { nowMs: 6000, active: true, idle: false, evidence: [] }, c)
    compare(s.statistics.today.activeMs, 5000)
    compare(s.statistics.currentSessionActiveMs, 5000)
    s = Model.observe(s, { nowMs: 11000, active: false, idle: true, evidence: [] }, c)
    compare(s.statistics.today.activeMs, 5000)
  }

  function test_completedBreakClosesStatisticsSession() {
    var s = Model.defaultSnapshot(1000)
    s.statistics.currentSessionActiveMs = 18 * 60000
    s.statistics.today.activeMs = 18 * 60000
    s.state = Model.State.Breaking
    s.activeBreakDurationMs = 20000
    s.breakEndsAtMs = 21000
    s = Model.completeBreak(s, 21000)
    compare(s.statistics.today.completed, 1)
    compare(s.statistics.today.shortBreaks, 1)
    compare(s.statistics.currentSessionActiveMs, 0)
    compare(s.statistics.today.sessions[0].durationMs, 18 * 60000)
    compare(s.statistics.today.sessions[0].outcome, "break")
  }

  function test_skippingDoesNotEndUninterruptedSession() {
    var s = Model.defaultSnapshot(1000)
    s.statistics.currentSessionActiveMs = 18 * 60000
    s.state = Model.State.Breaking
    s.breakEndsAtMs = 21000
    s = Model.skipBreak(s, 21000)
    compare(s.statistics.today.skipped, 1)
    compare(s.statistics.today.completed, 0)
    compare(s.statistics.currentSessionActiveMs, 18 * 60000)
    compare(s.statistics.today.sessions.length, 0)
  }

  function test_snoozesAreRecordedPerDay() {
    var c = config({ snoozeBudget: 3 })
    var s = Model.defaultSnapshot(1000)
    s = Model.delayNextBreak(s, 2000, 60000, c)
    compare(s.statistics.today.snoozed, 1)
  }

  function test_statisticsRollOverAtLocalDayBoundary() {
    var start = new Date(2026, 7, 24, 23, 59, 59).getTime()
    var nextDay = start + 2000
    var c = config({ focusMs: 60 * 60 * 1000 })
    var s = Model.defaultSnapshot(start)
    s.statistics.today.activeMs = 100000
    s.statistics.currentSessionActiveMs = 100000
    s = Model.observe(s, { nowMs: nextDay, active: true, idle: false, evidence: [] }, c)
    compare(s.statistics.days.length, 1)
    compare(s.statistics.days[0].activeMs, 100000)
    compare(s.statistics.today.dateKey, Model.localDayKey(nextDay))
    compare(s.statistics.today.activeMs, 2000)
    compare(s.statistics.currentSessionActiveMs, 102000)
  }

  function test_medianSessionDuration() {
    var s = Model.defaultSnapshot(1000)
    s.statistics.today.sessionDurationsMs = [30 * 60000, 10 * 60000, 20 * 60000]
    compare(Model.medianSessionDuration(s), 20 * 60000)
    s.statistics.today.sessionDurationsMs = [10 * 60000, 20 * 60000]
    compare(Model.medianSessionDuration(s), 15 * 60000)
  }

  function test_recoveryRejectsFutureStatisticsSession() {
    var now = 1000000
    var s = Model.defaultSnapshot(now)
    s.statistics.today.sessions = [{
      endedAtMs: now + 25 * 60 * 60 * 1000,
      durationMs: 1000,
      outcome: "break"
    }]
    compare(Model.recoverSnapshot(s, now), null)
  }

  function test_statisticsMigrateAndRemainBounded() {
    var now = new Date(2026, 7, 25, 12, 0, 0).getTime()
    var legacy = Model.copySnapshot({ lastObservedAtMs: now })
    compare(legacy.statistics.today.dateKey, Model.localDayKey(now))
    compare(legacy.statistics.today.activeMs, 0)

    var s = Model.defaultSnapshot(now)
    for (var index = 0; index < 20; index++) {
      s.statistics.today.sessions.push({ endedAtMs: now, durationMs: 1000, outcome: "break" })
      s.statistics.today.sessionDurationsMs.push(1000)
      var dayNumber = 24 - index
      var day = Model.defaultStatisticDay("2026-08-" + (dayNumber < 10 ? "0" : "") + dayNumber)
      day.activeMs = 1000
      s.statistics.days.push(day)
    }
    s = Model.copySnapshot(s)
    compare(s.statistics.today.sessions.length, 12)
    compare(s.statistics.today.sessionDurationsMs.length, 12)
    compare(s.statistics.days.length, 7)
  }
}

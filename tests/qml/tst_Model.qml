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

  function test_settingsRebuildFromDefaults() {
    var customized = Model.configFromSettings({
      focusMinutes: 25,
      officeHoursEnabled: true,
      officeStart: "22:30",
      mediaDetection: false
    })
    compare(customized.focusMs, 25 * 60000)
    verify(customized.officeHours.enabled)
    compare(customized.officeHours.startMinute, 22 * 60 + 30)
    verify(!customized.detectors.media)

    // Omarchy supplies no key after an override is removed. A fresh
    // reconciliation must restore defaults rather than retain old config.
    var restored = Model.configFromSettings({})
    compare(restored.focusMs, 20 * 60000)
    verify(!restored.officeHours.enabled)
    compare(restored.officeHours.startMinute, 8 * 60)
    verify(restored.detectors.media)
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

  function test_postpone() {
    var s = Model.defaultSnapshot(0)
    s.state = Model.State.Warning
    s = Model.postpone(s, 1000, 60000, config())
    compare(s.state, Model.State.Waiting)
    compare(s.postponedUntilMs, 61000)
    compare(s.snoozesUsed, 1)
    compare(s.totals.postponed, 1)
  }

  function test_postponeBudgetAndFocusedEnforcement() {
    var s = Model.defaultSnapshot(0)
    s.state = Model.State.Warning
    s.snoozesUsed = 1
    verify(!Model.canPostpone(s, config({ snoozeBudget: 1 })))
    verify(!Model.canPostpone(s, config({ enforcement: "focused" })))
    verify(Model.canPostpone(s, config({ snoozeBudget: 2, enforcement: "balanced" })))
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
    compare(Model.formatBarDuration(60000), "1m")
    compare(Model.formatBarDuration(60001), "2m")
  }

  function test_protectedExplanationAvoidsInternalLabels() {
    compare(Model.protectedExplanation("meeting"), "Held quietly while your meeting is active.")
    compare(Model.protectedExplanation("dictation"), "Held quietly while dictation is active.")
  }
}

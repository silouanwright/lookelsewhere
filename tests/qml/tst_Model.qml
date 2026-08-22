import QtQuick
import QtTest
import "../../Model.js" as Model

TestCase {
  name: "LookElsewhereModel"

  function config(overrides) {
    var value = { focusMs: 10000, breakMs: 5000, dueSoonMs: 2000, warningMs: 4000, finalMs: 1000, cooldownMs: 2000, maximumDelayMs: 10000 }
    for (var key in (overrides || {})) value[key] = overrides[key]
    return Model.normalizeConfig(value)
  }

  function test_overnightOfficeHours() {
    var hours = { enabled: true, startMinute: 20 * 60, endMinute: 2 * 60 }
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 23, 0), hours))
    verify(Model.inOfficeHours(new Date(2026, 7, 22, 1, 0), hours))
    verify(!Model.inOfficeHours(new Date(2026, 7, 22, 12, 0), hours))
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
    s = Model.observe(s, { nowMs: 11000, active: true, idle: false, evidence: [{ category: "meeting", active: true, confidence: 0.9 }] }, c)
    compare(s.state, Model.State.Protected)
    compare(s.protectedCategory, "meeting")
    s = Model.observe(s, { nowMs: 12000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Waiting)
    s = Model.observe(s, { nowMs: 15000, active: true, idle: false, evidence: [] }, c)
    compare(s.state, Model.State.Warning)
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
    s = Model.postpone(s, 1000, 60000)
    compare(s.state, Model.State.Waiting)
    compare(s.postponedUntilMs, 61000)
    compare(s.snoozesUsed, 1)
    compare(s.totals.postponed, 1)
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
  }
}

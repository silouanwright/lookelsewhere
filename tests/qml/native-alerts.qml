import QtQuick
import Quickshell
import "../.." as Look
ShellRoot {
  QtObject {
    id: fake
    property var config: ({ alertPresentation: "custom" })
    property bool stateLoaded: true
    property bool demoMode: false
    property string phase: "warning"
    property var snapshot: ({ naturalBreakDecision: null })
    property bool plannedActive: false
    property string plannedName: ""
    property bool naturalBreakToastVisible: false
    property string naturalBreakMessage: "Rest counted"
  }
  Look.NativeAlerts {
    id: alerts
    controller: fake
    property var received: []
    function enqueue(title, body, action) { received = received.concat([action]) }
  }
  Timer { interval: 100; running: true; onTriggered: {
    function check(value, message) { if (!value) throw new Error(message) }
    check(alerts.received.length === 0, "Custom mode sent a native notice")
    fake.config = { alertPresentation: "native" }
    alerts.reconcile()
    check(alerts.received.length === 1, "Native mode missed warning")
    alerts.reconcile()
    check(alerts.received.length === 1, "Repeated snapshot duplicated warning")
    fake.phase = "final-countdown"
    alerts.reconcile()
    check(alerts.received.length === 1, "Final countdown sent native warning")
    fake.phase = "working"
    fake.naturalBreakToastVisible = true
    fake.snapshot = { naturalBreakDecision: { decidedAtMs: 123 } }
    alerts.reconcile()
    check(alerts.received.length === 2, "Missing natural-break notice")
    check(alerts.received[1][1] === "undoNativeNotice" && alerts.received[1][2] === "123", "Undo missing identity guard")
    alerts.reconcile()
    check(alerts.received.length === 2, "Duplicate natural-break notice")
    fake.config = { alertPresentation: "both" }
    fake.phase = "planned-ready"
    fake.naturalBreakToastVisible = false
    alerts.reconcile()
    check(alerts.received.length === 3, "Both mode missed planned notice")
    console.log("PASS: routing, deduplication, countdown exclusion, guarded Undo, both mode")
    Qt.quit()
  } }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root
  required property var controller
  property string lastPhase: ""
  property real lastDecision: 0
  property var pending: []
  readonly property bool enabledForAlerts: controller.config.alertPresentation === "native"
    || controller.config.alertPresentation === "both"

  function enqueue(title, body, action) {
    var command = ["/usr/bin/omarchy", "notification", "send", "--app-name", "LookElsewhere",
      "--urgency", "normal", "--expire-time", "6000", Model.plainUiText(title),
      Model.plainUiText(body), "--exec", "/usr/bin/omarchy-shell"]
    pending = pending.concat([command.concat(action)]).slice(-2)
    drain()
  }

  function drain() {
    if (sender.running || pending.length === 0) return
    sender.command = pending[0]
    pending = pending.slice(1)
    sender.running = true
  }

  function reconcile() {
    if (!controller.stateLoaded && !controller.demoMode) return
    var phase = controller.phase
    var decision = controller.snapshot.naturalBreakDecision
    var decisionTime = decision ? Number(decision.decidedAtMs || 0) : 0
    if (enabledForAlerts) {
      if (phase !== lastPhase && (phase === "warning" || phase === "planned-ready")) {
        enqueue(controller.plannedActive ? controller.plannedName : qsTr("Upcoming eye break"),
          phase === "planned-ready" ? qsTr("Your planned break is ready. Open LookElsewhere for break controls.")
            : qsTr("Your break is approaching. Open LookElsewhere to start now or snooze."),
          ["look-elsewhere-panel", "open"])
      }
      if (decisionTime > 0 && decisionTime !== lastDecision && controller.naturalBreakToastVisible) {
        enqueue(qsTr("Natural break counted"), controller.naturalBreakMessage + " " + qsTr("Activate this notification to undo."),
          ["look-elsewhere", "undoNativeNotice", String(decisionTime)])
      }
    }
    lastPhase = phase
    lastDecision = decisionTime
  }

  Connections {
    target: root.controller
    function onSnapshotChanged() { Qt.callLater(root.reconcile) }
    function onStateLoadedChanged() { Qt.callLater(root.reconcile) }
  }
  onEnabledForAlertsChanged: {
    if (!enabledForAlerts) pending = []
    // Changing delivery mode should also present an already-active notice.
    lastPhase = ""
    lastDecision = 0
    Qt.callLater(root.reconcile)
  }
  Component.onCompleted: Qt.callLater(root.reconcile)

  Process {
    id: sender
    onExited: function(code, status) {
      if (code !== 0) console.warn("LookElsewhere native notification failed: " + code)
      Qt.callLater(root.drain)
    }
  }
}

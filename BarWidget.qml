import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.silouanwright.look-elsewhere"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var panelItem: panelLoader.status === Loader.Ready ? panelLoader.item : null
  readonly property bool opened: panelItem ? panelItem.opened === true : false

  function injectPanel() {
    var target = root.panelItem
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.service = root.service
  }

  function open() { if (panelItem) panelItem.open() }
  function close() { if (panelItem) panelItem.close() }
  function togglePanel() { if (panelItem) panelItem.toggle() }
  function closeForPopoutSwitch() { if (panelItem) panelItem.closeForPopoutSwitch() }

  onBarChanged: injectPanel()
  onSettingsChanged: {
    injectPanel()
    if (service) service.configure(settings)
  }
  onServiceChanged: {
    injectPanel()
    if (service) service.configure(settings)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.service && root.service.state === "breaking" ? "󰈈" : "󰈉"
    active: root.service && (root.service.state === "due-soon" || root.service.interrupting)
    tooltipText: root.service ? qsTr("%1 · %2").arg(root.service.label).arg(root.service.remainingText) : qsTr("Look Elsewhere")
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton && root.service) root.service.takeBreak()
      else root.togglePanel()
    }
  }
}

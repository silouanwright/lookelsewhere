import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.silouanwright.look-elsewhere"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    target.bar = root.bar
    target.settings = root.settings
    target.anchorItem = button
    target.hostWidget = root
    target.service = root.service
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

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
    tooltipText: root.service ? root.service.label + " · " + root.service.remainingText : "Look Elsewhere"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton && root.service) root.service.takeBreak()
      else root.togglePanel()
    }
  }
}

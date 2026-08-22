import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root
  moduleName: "io.github.silouanwright.look-elsewhere"

  readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var panelItem: panelLoader.status === Loader.Ready ? panelLoader.item : null
  readonly property bool opened: panelItem ? panelItem.opened === true : false
  readonly property string displayMode: {
    var value = settings && settings.displayMode !== undefined ? String(settings.displayMode) : "icon-and-time"
    return ["icon", "time", "icon-and-time"].indexOf(value) >= 0 ? value : "icon-and-time"
  }
  readonly property bool showIcon: displayMode !== "time" || (bar && bar.vertical)
  readonly property bool showTime: displayMode !== "icon" && (!bar || !bar.vertical)
  readonly property string compactTime: service ? (service.idlePauseActive ? qsTr("Idle") : Model.formatBarDuration(service.remainingMs)) : "—"

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

  // Keep the single IPC authority on the bar-widget entry point. Panel
  // instances are reconstructed during bar-position and theme changes; an
  // IpcHandler inside those transient instances can briefly leave an obsolete
  // handler authoritative after the new panel has appeared.
  IpcHandler {
    target: "look-elsewhere-panel"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? -1 : Math.max(Style.bar.iconSlot, barContent.implicitWidth + scaledHorizontalMargin * 2)
    active: root.service && (root.service.phase === "due-soon" || root.service.interrupting)
    tooltipText: ""
    Accessible.role: Accessible.Button
    Accessible.name: root.service
      ? qsTr("LookElsewhere: %1, %2").arg(root.service.label).arg(root.service.remainingText)
      : qsTr("LookElsewhere")
    Accessible.onPressAction: root.togglePanel()

    Row {
      id: barContent
      anchors.centerIn: parent
      spacing: root.showIcon && root.showTime ? Style.space(5) : 0

      BarBreakIcon {
        visible: root.showIcon
        // Keep the compact 256-unit SVG on a clean 1/16 scale. Using the
        // nearby font-derived ~18px size makes the rounded bed corner land on
        // an isolated antialiased pixel that reads as a rendering defect.
        width: Style.space(16)
        height: width
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        visible: root.showTime
        text: root.compactTime
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.Medium
        renderType: Text.NativeRendering
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton && root.service) root.service.takeBreak()
      else root.togglePanel()
    }
  }
}

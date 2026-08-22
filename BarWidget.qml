import QtQuick
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
  readonly property string compactTime: service ? Model.formatBarDuration(service.remainingMs) : "—"

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

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: vertical ? -1 : Math.max(Style.bar.iconSlot, barContent.implicitWidth + scaledHorizontalMargin * 2)
    active: root.service && (root.service.state === "due-soon" || root.service.interrupting)
    tooltipText: root.service ? qsTr("%1 · %2").arg(root.service.label).arg(root.service.remainingText) : qsTr("Look Elsewhere")

    Row {
      id: barContent
      anchors.centerIn: parent
      spacing: root.showIcon && root.showTime ? Style.space(5) : 0

      Text {
        visible: root.showIcon
        text: root.service && root.service.state === "breaking" ? "󰈈" : "󰈉"
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.bar.iconFont
        renderType: Text.NativeRendering
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        id: countdown
        visible: root.showTime
        width: timeMetrics.stableWidth
        text: root.compactTime
        color: button.active && button.useActiveColor ? button.activeColor : button.foreground
        font.family: button.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignRight
        renderType: Text.NativeRendering
        anchors.verticalCenter: parent.verticalCenter

        FontMetrics {
          id: timeMetrics
          font.family: countdown.font.family
          font.pixelSize: countdown.font.pixelSize
          font.weight: countdown.font.weight
          // Stable width prevents final-minute updates from shifting the bar.
          readonly property real stableWidth: Math.max(advanceWidth("00s"), advanceWidth("00m"))
        }
      }
    }

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.MiddleButton && root.service) root.service.takeBreak()
      else root.togglePanel()
    }
  }
}

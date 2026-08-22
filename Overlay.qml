import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var service: null
  property var shell: null
  property var manifest: null

  readonly property bool visibleState: service && service.interrupting
  readonly property bool breaking: service && service.state === "breaking"

  Variants {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: window
      required property var modelData
      screen: modelData
      visible: root.visibleState
      anchors { top: true; bottom: true; left: true; right: true }
      color: root.breaking ? Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.94) : "transparent"
      exclusionMode: ExclusionMode.Ignore
      mask: Region { item: root.breaking ? fullScreenHitArea : warningCard }

      readonly property bool authoritative: Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === modelData.name

      WlrLayershell.namespace: "look-elsewhere"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: root.breaking && authoritative ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      Item {
        id: fullScreenHitArea
        anchors.fill: parent
        visible: root.breaking
        enabled: root.breaking && window.authoritative

        ColumnLayout {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(48), Style.space(520))
          spacing: Style.space(18)

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰈉"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.space(54)
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Look elsewhere"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.displayLarge
            font.weight: Font.DemiBold
          }
          Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: "Let your eyes settle on something distant. Breathe. The screen will still be here."
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
            wrapMode: Text.WordWrap
          }
          Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.service ? root.service.remainingText : ""
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.display
            font.weight: Font.DemiBold
          }
          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.space(10)
            OverlayButton {
              text: "Skip break"
              visible: root.service && root.service.config.enforcement !== "focused"
              onActivated: if (root.service) root.service.skipBreak()
            }
            OverlayButton {
              text: "+1 minute"
              visible: root.service && root.service.config.enforcement === "gentle"
              onActivated: if (root.service) root.service.postponeMinutes(1)
            }
          }
        }

        Keys.onEscapePressed: {
          if (root.service && root.service.config.enforcement !== "focused") root.service.skipBreak()
        }
      }

      Rectangle {
        id: warningCard
        visible: !root.breaking
        anchors.top: parent.top
        anchors.topMargin: Style.space(56)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - Style.space(32), Style.space(520))
        height: warningContent.implicitHeight + Style.space(28)
        radius: Style.cornerRadius
        color: Color.popups.background
        border.width: 1
        border.color: Color.popups.border

        RowLayout {
          id: warningContent
          anchors.fill: parent
          anchors.margins: Style.space(14)
          spacing: Style.space(12)

          Text {
            text: "󰈉"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.display
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(2)
            Text {
              text: root.service && root.service.state === "final-countdown" ? "Starting break" : "Almost time"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              font.weight: Font.DemiBold
            }
            Text {
              text: "Your eyes will appreciate this."
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.body
            }
          }
          Text {
            text: root.service ? root.service.remainingText : ""
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.heading
            font.weight: Font.DemiBold
          }
          OverlayButton {
            text: "+5m"
            visible: window.authoritative
            onActivated: if (root.service) root.service.postponeMinutes(5)
          }
          OverlayButton {
            text: "Now"
            primary: true
            visible: window.authoritative
            onActivated: if (root.service) root.service.takeBreak()
          }
        }
      }
    }
  }

  component OverlayButton: Rectangle {
    id: button
    property string text: ""
    property bool primary: false
    signal activated()
    implicitWidth: label.implicitWidth + Style.space(24)
    implicitHeight: Style.space(36)
    radius: height / 2
    color: primary ? Color.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, mouse.containsMouse ? 0.14 : 0.08)
    Text {
      id: label
      anchors.centerIn: parent
      text: button.text
      color: button.primary ? Color.background : Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
    }
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.activated()
    }
  }
}

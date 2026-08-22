import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.silouanwright.look-elsewhere"
  ipcTarget: "look-elsewhere-panel"

  property var service: null
  property var anchorItem: null
  property var hostWidget: null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.62)
  readonly property color accent: bar ? bar.urgent : Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function syncSettings() { if (service) service.configure(settings) }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    contentWidth: popup.fittedContentWidth(Style.space(390))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    ColumnLayout {
      id: content
      anchors.fill: parent
      spacing: Style.space(14)

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(12)

        Rectangle {
          Layout.preferredWidth: Style.space(44)
          Layout.preferredHeight: width
          radius: width / 2
          color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)
          Text {
            anchors.centerIn: parent
            text: "󰈉"
            color: root.accent
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(2)
          Text {
            text: root.service ? root.service.label : "Look Elsewhere"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            font.weight: Font.DemiBold
          }
          Text {
            text: root.service ? root.service.remainingText : "Starting…"
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: Style.space(7)
        radius: height / 2
        color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.10)
        Rectangle {
          width: parent.width * (root.service ? root.service.progress : 0)
          height: parent.height
          radius: height / 2
          color: root.accent
        }
      }

      Text {
        Layout.fillWidth: true
        text: root.service && root.service.protectedSummary !== "" ? root.service.protectedSummary : "Only active screen time counts. Meetings, videos, fullscreen work, and dictation pause interruptions automatically."
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        ActionButton {
          Layout.fillWidth: true
          text: "Break now"
          primary: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onActivated: { if (root.service) root.service.takeBreak(); root.close() }
        }
        ActionButton {
          Layout.fillWidth: true
          text: "Pause 1h"
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onActivated: { if (root.service) root.service.pauseMinutes(60); root.close() }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          Layout.fillWidth: true
          text: root.service && root.service.demoMode ? "Demo mode" : "Smart pause is on"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          text: "Middle-click the eye for a break"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }

  component ActionButton: Rectangle {
    id: action
    property string text: ""
    property bool primary: false
    property color foreground: "white"
    property color accent: "white"
    property string fontFamily: "sans"
    signal activated()
    implicitHeight: Style.space(40)
    radius: Style.cornerRadius
    color: primary ? accent : Qt.rgba(foreground.r, foreground.g, foreground.b, mouse.containsMouse ? 0.13 : 0.08)
    Text {
      anchors.centerIn: parent
      text: action.text
      color: action.primary ? Color.background : action.foreground
      font.family: action.fontFamily
      font.weight: Font.DemiBold
    }
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: action.activated()
    }
  }
}

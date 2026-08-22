import QtQuick
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

  // Popup roles are independent from bar roles in an Omarchy theme.
  readonly property color foreground: Color.popups.text
  readonly property color muted: Color.muted
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool manuallyPaused: service && service.state === "waiting-for-pause" && service.snapshot.pauseReason === "manual"

  function syncSettings() { if (service) service.configure(settings) }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    // The control surface belongs spatially to the eye button. Warning and
    // break surfaces are separate and intentionally centered by Overlay.qml.
    centerOnBar: false
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
            text: root.service ? root.service.label : qsTr("Look Elsewhere")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            font.weight: Font.DemiBold
          }
          Text {
            text: root.service ? root.service.remainingText : qsTr("Starting…")
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
        text: root.service && root.service.protectedSummary !== "" ? root.service.protectedSummary : qsTr("Only active screen time counts. Meetings, videos, fullscreen work, and dictation pause interruptions automatically.")
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Text {
        Layout.fillWidth: true
        visible: root.service && root.service.recoveryWarning !== ""
        text: root.service ? root.service.recoveryWarning : ""
        color: Color.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.space(8)

        Button {
          Layout.fillWidth: true
          text: qsTr("Break now")
          selected: true
          focusable: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: { if (root.service) root.service.takeBreak(); root.close() }
        }
        Button {
          Layout.fillWidth: true
          text: root.manuallyPaused ? qsTr("Resume") : qsTr("Pause 1h")
          bordered: true
          focusable: true
          foreground: root.foreground
          accent: root.accent
          fontFamily: root.fontFamily
          onClicked: {
            if (root.service) {
              if (root.manuallyPaused) root.service.resume()
              else root.service.pauseMinutes(60)
            }
            root.close()
          }
        }
      }

      Text {
        Layout.fillWidth: true
        text: {
          if (!root.service || !root.service.snapshot || !root.service.snapshot.totals) return qsTr("No break history yet")
          var totals = root.service.snapshot.totals
          return qsTr("History · %1 completed · %2 postponed · %3 delayed")
            .arg(Number(totals.completed || 0))
            .arg(Number(totals.postponed || 0))
            .arg(Number(totals.delayed || 0))
        }
        color: root.muted
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          Layout.fillWidth: true
          text: root.service && root.service.demoMode ? qsTr("Demo mode") : qsTr("Smart pause is on")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          text: qsTr("Middle-click the eye for a break")
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }
    }
  }

}

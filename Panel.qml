import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.silouanwright.look-elsewhere"
  ipcTarget: "look-elsewhere-panel"
  manageIpc: false

  property var service: null
  property var anchorItem: null
  property var hostWidget: null

  // Popup roles are independent from bar roles in an Omarchy theme.
  readonly property color foreground: Color.popups.text
  readonly property color muted: Color.muted
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool manuallyPaused: service && service.phase === "waiting-for-pause" && service.snapshot.pauseReason === "manual"

  function syncSettings() { if (service) service.configure(settings) }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()
  onOpenedChanged: {
    if (opened) initialFocusTimer.restart()
    else initialFocusTimer.stop()
  }

  // KeyboardPanel primes the layer-shell surface before settling to
  // OnDemand focus. Move focus once that prime has completed so a panel
  // opened from IPC or a keybinding starts on the primary action instead of
  // requiring a throwaway first Tab press.
  Timer {
    id: initialFocusTimer
    interval: 100
    onTriggered: if (root.opened) breakNowButton.forceActiveFocus()
  }

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    // The control surface belongs spatially to the eye button. Warning and
    // break surfaces are separate and intentionally centered by Overlay.qml.
    centerOnBar: false
    focusTarget: breakNowButton
    contentWidth: popup.fittedContentWidth(Style.space(300))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    Flickable {
      id: panelScroll
      anchors.fill: parent
      contentWidth: width
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      ColumnLayout {
        id: content
        width: panelScroll.width
        spacing: Style.space(16)

        RowLayout {
          Layout.fillWidth: true
          Layout.leftMargin: Style.space(2)
          Layout.rightMargin: Style.space(2)
          spacing: Style.space(8)

          Rectangle {
            Layout.preferredWidth: Style.space(32)
            Layout.preferredHeight: Layout.preferredWidth
            radius: width / 2
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.16)

            Text {
              anchors.centerIn: parent
              text: "󰈉"
              color: root.accent
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              Accessible.ignored: true
            }
          }

          Text {
            text: root.service ? root.service.label : qsTr("Look Elsewhere")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }

        Text {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(4)
          Layout.bottomMargin: Style.space(4)
          text: root.service ? root.service.remainingText : qsTr("Starting…")
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.display * 1.55
          font.weight: Font.DemiBold
          horizontalAlignment: Text.AlignHCenter
          Accessible.role: Accessible.StaticText
          Accessible.name: qsTr("Time remaining: %1").arg(text)
        }

        Text {
          Layout.fillWidth: true
          visible: root.service && root.service.protectedSummary !== ""
          text: root.service ? root.service.protectedSummary : ""
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }

        Text {
          Layout.fillWidth: true
          visible: root.service && root.service.recoveryWarning !== ""
          text: root.service ? root.service.recoveryWarning : ""
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Button {
            id: breakNowButton
            Layout.fillWidth: true
            text: qsTr("Break now")
            selected: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: pauseButton
            KeyNavigation.backtab: pauseButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.takeBreak(); root.close() }
          }

          Button {
            id: pauseButton
            Layout.fillWidth: true
            text: root.manuallyPaused ? qsTr("Resume") : qsTr("Pause 1h")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: breakNowButton
            KeyNavigation.backtab: breakNowButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
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
          Layout.topMargin: Style.space(2)
          text: {
            if (!root.service || !root.service.snapshot || !root.service.snapshot.totals) return qsTr("No break history yet")
            var totals = root.service.snapshot.totals
            return qsTr("%1 completed · %2 postponed · %3 delayed")
              .arg(Number(totals.completed || 0))
              .arg(Number(totals.postponed || 0))
              .arg(Number(totals.delayed || 0))
          }
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

      }
    }
  }

}

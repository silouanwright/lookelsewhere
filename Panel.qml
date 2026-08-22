import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
  property string page: "now"

  // Popup roles are independent from bar roles in an Omarchy theme.
  readonly property color foreground: Color.popups.text
  readonly property color muted: Color.muted
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool manuallyPaused: service && service.phase === "waiting-for-pause" && service.snapshot.pauseReason === "manual"
  readonly property bool delayActionsVisible: !manuallyPaused && service && service.canPostpone
  readonly property int remainingSeconds: service ? Math.max(0, Math.ceil(service.remainingMs / 1000)) : 0
  readonly property int remainingMinutesPart: Math.floor(remainingSeconds / 60)
  readonly property int remainingSecondsPart: remainingSeconds % 60

  function syncSettings() { if (service) service.configure(settings) }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()
  onOpenedChanged: {
    if (opened) initialFocusTimer.restart()
    else {
      initialFocusTimer.stop()
      page = "now"
    }
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
    contentWidth: popup.fittedContentWidth(Style.space(260))
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
          spacing: Style.space(8)

          Rectangle {
            Layout.preferredWidth: Style.space(28)
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
            Layout.fillWidth: true
            text: root.page === "stats" ? qsTr("Break history") : qsTr("Break starts in")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }

          Button {
            id: statsButton
            iconText: "󰄧"
            tooltipText: root.page === "stats" ? qsTr("Back to timer") : qsTr("Break history")
            selected: root.page === "stats"
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            horizontalPadding: Style.space(5)
            verticalPadding: Style.space(4)
            KeyNavigation.tab: settingsButton
            KeyNavigation.backtab: root.page === "stats"
              ? settingsButton
              : (root.delayActionsVisible ? postpone15Button : breakNowButton)
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.page = root.page === "stats" ? "now" : "stats"
          }

          Button {
            id: settingsButton
            iconText: "󰒓"
            tooltipText: qsTr("Edit Look Elsewhere settings")
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            horizontalPadding: Style.space(5)
            verticalPadding: Style.space(4)
            KeyNavigation.tab: root.page === "stats" ? statsButton : breakNowButton
            KeyNavigation.backtab: statsButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: {
              root.close()
              settingsEditor.running = true
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(4)
          Layout.bottomMargin: Style.space(4)
          Layout.alignment: Qt.AlignHCenter
          visible: root.page === "now"
          spacing: Style.space(7)
          Accessible.role: Accessible.StaticText
          Accessible.name: qsTr("Time remaining: %1").arg(root.service ? root.service.remainingText : qsTr("Starting"))

          Row {
            spacing: 0
            RollingNumber {
              value: root.remainingMinutesPart
              color: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.display * 1.55
              fontWeight: Font.DemiBold
              reducedMotion: root.service && root.service.config.reducedMotion
            }
            Text {
              text: qsTr("m")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display * 1.55
              font.weight: Font.DemiBold
              Accessible.ignored: true
            }
          }

          Row {
            spacing: 0
            RollingNumber {
              value: root.remainingSecondsPart
              color: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.display * 1.55
              fontWeight: Font.DemiBold
              reducedMotion: root.service && root.service.config.reducedMotion
            }
            Text {
              text: qsTr("s")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display * 1.55
              font.weight: Font.DemiBold
              Accessible.ignored: true
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          visible: root.page === "stats"
          spacing: Style.space(10)

          Text {
            Layout.fillWidth: true
            text: root.service && root.service.snapshot && root.service.snapshot.totals
              ? qsTr("%1 completed").arg(Number(root.service.snapshot.totals.completed || 0))
              : qsTr("0 completed")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }
          Text {
            Layout.fillWidth: true
            text: root.service && root.service.snapshot && root.service.snapshot.totals
              ? qsTr("%1 postponed · %2 delayed")
                  .arg(Number(root.service.snapshot.totals.postponed || 0))
                  .arg(Number(root.service.snapshot.totals.delayed || 0))
              : qsTr("0 postponed · 0 delayed")
            color: root.muted
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Text {
          Layout.fillWidth: true
          visible: root.page === "now" && root.service && root.service.protectedSummary !== ""
          text: root.service ? root.service.protectedSummary : ""
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }

        Text {
          Layout.fillWidth: true
          visible: root.page === "now" && root.service && root.service.recoveryWarning !== ""
          text: root.service ? root.service.recoveryWarning : ""
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter
          visible: root.page === "now"
          spacing: Style.space(8)

          Button {
            id: breakNowButton
            text: qsTr("Break now")
            selected: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: root.delayActionsVisible ? postpone1Button : statsButton
            KeyNavigation.backtab: settingsButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.takeBreak(); root.close() }
          }

        }

        RowLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter
          visible: root.page === "now" && root.delayActionsVisible
          spacing: Style.space(6)

          Button {
            id: postpone1Button
            text: qsTr("+1m")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: postpone5Button
            KeyNavigation.backtab: breakNowButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Delay next break by 1 minute")
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.postponeMinutes(1); root.close() }
          }

          Button {
            id: postpone5Button
            text: qsTr("+5m")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: postpone15Button
            KeyNavigation.backtab: postpone1Button
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Delay next break by 5 minutes")
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.postponeMinutes(5); root.close() }
          }

          Button {
            id: postpone15Button
            text: qsTr("+15m")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: statsButton
            KeyNavigation.backtab: postpone5Button
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Delay next break by 15 minutes")
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.postponeMinutes(15); root.close() }
          }
        }

      }
    }
  }

  Process {
    id: settingsEditor
    command: ["omarchy", "launch", "config", "editor", Quickshell.env("HOME") + "/.config/omarchy/shell.json"]
  }

}

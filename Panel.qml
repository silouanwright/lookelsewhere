import QtQuick
import QtQuick.Controls
import QtQuick.Effects
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
  onOpenedChanged: if (!opened) page = "now"

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    // The control surface belongs spatially to the eye button. Warning and
    // break surfaces are separate and intentionally centered by Overlay.qml.
    centerOnBar: false
    focusTarget: neutralFocus
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

      Item {
        id: neutralFocus
        width: 0
        height: 0
        focus: true
        Keys.onEscapePressed: root.close()
      }

      ColumnLayout {
        id: content
        width: panelScroll.width
        spacing: Style.space(16)

        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Item {
            Layout.fillWidth: true
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
            KeyNavigation.backtab: root.page === "stats" ? settingsButton
              : (root.page === "options" ? editSettingsButton
                : (root.delayActionsVisible ? postpone15Button : breakNowButton))
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.page = root.page === "stats" ? "now" : "stats"
          }

          Button {
            id: settingsButton
            iconText: "󰒓"
            tooltipText: root.page === "options" ? qsTr("Back to timer") : qsTr("Look Elsewhere options")
            selected: root.page === "options"
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            horizontalPadding: Style.space(5)
            verticalPadding: Style.space(4)
            KeyNavigation.tab: root.page === "stats" ? statsButton
              : (root.page === "options" ? pauseBreaksButton : breakNowButton)
            KeyNavigation.backtab: statsButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.page = root.page === "options" ? "now" : "options"
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          visible: root.page === "now"
          spacing: Style.space(4)

          Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.space(34)
            Layout.preferredHeight: Layout.preferredWidth
            Accessible.ignored: true

            Image {
              anchors.fill: parent
              source: Qt.resolvedUrl("assets/break.svg")
              sourceSize: Qt.size(width, height)
              fillMode: Image.PreserveAspectFit
              smooth: true
              layer.enabled: true
              layer.effect: MultiEffect {
                colorization: 1
                colorizationColor: root.accent
              }
            }
          }

          Text {
            Layout.fillWidth: true
            Layout.bottomMargin: -Style.space(5)
            text: qsTr("Break starts in")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }

          Row {
            Layout.alignment: Qt.AlignHCenter
            // Monospace themes reserve a full character cell around the
            // colon. Pull the number groups into that cell so the clock reads
            // as one compact value instead of three separated tokens.
            spacing: -Style.space(2)
            Accessible.role: Accessible.StaticText
            Accessible.name: qsTr("Time remaining: %1").arg(root.service ? root.service.remainingText : qsTr("Starting"))

            RollingNumber {
              value: root.remainingMinutesPart
              minimumDigits: 2
              color: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.display * 1.55
              fontWeight: Font.DemiBold
              reducedMotion: root.service && root.service.config.reducedMotion
            }

            Text {
              text: ":"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display * 1.55
              font.weight: Font.DemiBold
              Accessible.ignored: true
            }

            RollingNumber {
              value: root.remainingSecondsPart
              minimumDigits: 2
              color: root.foreground
              fontFamily: root.fontFamily
              fontSize: Style.font.display * 1.55
              fontWeight: Font.DemiBold
              reducedMotion: root.service && root.service.config.reducedMotion
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          visible: root.page === "stats"
          spacing: Style.space(10)

          Text {
            Layout.fillWidth: true
            text: qsTr("Break history")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }

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

        ColumnLayout {
          Layout.fillWidth: true
          visible: root.page === "options"
          spacing: Style.space(8)

          Text {
            Layout.fillWidth: true
            text: qsTr("Options")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }

          Button {
            id: pauseBreaksButton
            Layout.alignment: Qt.AlignHCenter
            text: root.manuallyPaused ? qsTr("Resume breaks") : qsTr("Pause breaks")
            selected: root.manuallyPaused
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: stopButton
            KeyNavigation.backtab: settingsButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            onClicked: {
              if (!root.service) return
              if (root.manuallyPaused) root.service.resume()
              else root.service.pauseBreaks()
            }
          }

          Button {
            id: stopButton
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Stop Look Elsewhere")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: editSettingsButton
            KeyNavigation.backtab: pauseBreaksButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Stop and disable Look Elsewhere")
            Accessible.onPressAction: clicked()
            onClicked: {
              root.close()
              stopPlugin.running = true
            }
          }

          Button {
            id: editSettingsButton
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Edit settings file")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: statsButton
            KeyNavigation.backtab: stopButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            onClicked: {
              root.close()
              settingsEditor.running = true
            }
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
            tooltipText: qsTr("Snooze for 1 minute")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: postpone5Button
            KeyNavigation.backtab: breakNowButton
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Snooze next break for 1 minute")
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.postponeMinutes(1); root.close() }
          }

          Button {
            id: postpone5Button
            text: qsTr("+5m")
            tooltipText: qsTr("Snooze for 5 minutes")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: postpone15Button
            KeyNavigation.backtab: postpone1Button
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Snooze next break for 5 minutes")
            Accessible.onPressAction: clicked()
            onClicked: { if (root.service) root.service.postponeMinutes(5); root.close() }
          }

          Button {
            id: postpone15Button
            text: qsTr("+15m")
            tooltipText: qsTr("Snooze for 15 minutes")
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: statsButton
            KeyNavigation.backtab: postpone5Button
            Keys.onEscapePressed: root.close()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Snooze next break for 15 minutes")
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

  Process {
    id: stopPlugin
    command: ["omarchy", "plugin", "disable", root.moduleName]
  }

}

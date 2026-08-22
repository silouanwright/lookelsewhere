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
  property bool keyboardHintsVisible: false

  // Popup roles are independent from bar roles in an Omarchy theme.
  readonly property color foreground: Color.popups.text
  readonly property color muted: Color.muted
  readonly property color accent: Color.accent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool manuallyPaused: service && service.phase === "waiting-for-pause" && service.snapshot.pauseReason === "manual"
  readonly property bool idlePaused: service && service.idlePauseActive
  readonly property bool delayActionsVisible: !manuallyPaused && service
  readonly property bool delayActionsEnabled: delayActionsVisible && service.canPostpone
  readonly property int snoozesRemaining: service
    ? Math.max(0, Number(service.config.snoozeBudget || 0) - Number(service.snapshot.snoozesUsed || 0))
    : 0
  readonly property string snoozeBudgetSummary: service
    ? qsTr("%1 of %2 snoozes used")
        .arg(Number(service.snapshot.snoozesUsed || 0))
        .arg(Number(service.config.snoozeBudget || 0))
    : ""
  readonly property string snoozeUnavailableSummary: service
    ? snoozeBudgetSummary : ""
  readonly property string snoozeAvailabilitySummary: snoozesRemaining === 0
        ? qsTr("No snoozes available")
        : qsTr("Snoozes available: %1").arg(snoozesRemaining)
  readonly property int remainingSeconds: service ? Math.max(0, Math.ceil(service.remainingMs / 1000)) : 0
  readonly property int remainingMinutesPart: Math.floor(remainingSeconds / 60)
  readonly property int remainingSecondsPart: remainingSeconds % 60
  readonly property real clockSeparatorOverlap: Math.max(0,
    (clockColonMetrics.advanceWidth - clockColonMetrics.tightBoundingRect.width) / 2)

  TextMetrics {
    id: clockColonMetrics
    text: ":"
    font.family: root.fontFamily
    font.pixelSize: Style.font.display * 1.55
    font.weight: Font.Bold
  }

  function syncSettings() { if (service) service.configure(settings) }
  function takeBreakAndClose() {
    if (service) service.takeBreak()
    close()
  }
  function postponeAndClose(minutes) {
    if (!service || !delayActionsEnabled) return
    service.delayNextBreakMinutes(minutes)
    close()
  }
  function toggleManualPause() {
    if (service && !service.interrupting) service.togglePause()
  }
  function togglePage(name) { page = page === name ? "now" : name }
  function dismissHintsOrClose() {
    if (keyboardHintsVisible) keyboardHintsVisible = false
    else close()
  }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()
  onOpenedChanged: if (!opened) {
    page = "now"
    keyboardHintsVisible = false
  }

  // Window-local mnemonics complement native Tab/Backtab traversal. They are
  // intentionally inactive whenever the anchored panel is closed.
  Shortcut { sequence: "B"; context: Qt.ApplicationShortcut; enabled: root.opened; onActivated: root.takeBreakAndClose() }
  Shortcut { sequence: "1"; context: Qt.ApplicationShortcut; enabled: root.opened && root.delayActionsEnabled; onActivated: root.postponeAndClose(1) }
  Shortcut { sequence: "2"; context: Qt.ApplicationShortcut; enabled: root.opened && root.delayActionsEnabled; onActivated: root.postponeAndClose(5) }
  Shortcut { sequence: "3"; context: Qt.ApplicationShortcut; enabled: root.opened && root.delayActionsEnabled; onActivated: root.postponeAndClose(15) }
  Shortcut { sequence: "P"; context: Qt.ApplicationShortcut; enabled: root.opened && root.service && !root.service.interrupting; onActivated: root.toggleManualPause() }
  Shortcut { sequence: "H"; context: Qt.ApplicationShortcut; enabled: root.opened; onActivated: root.togglePage("stats") }
  Shortcut { sequence: "O"; context: Qt.ApplicationShortcut; enabled: root.opened; onActivated: root.togglePage("options") }
  Shortcut { sequence: "E"; context: Qt.ApplicationShortcut; enabled: root.opened && root.page === "options"; onActivated: { root.close(); settingsEditor.running = true } }
  Shortcut { sequence: "Shift+D"; context: Qt.ApplicationShortcut; enabled: root.opened && root.page === "options"; onActivated: { root.close(); stopPlugin.running = true } }
  Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; enabled: root.opened; onActivated: root.close() }
  Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; enabled: root.opened; onActivated: root.keyboardHintsVisible = !root.keyboardHintsVisible }

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
        Keys.onEscapePressed: root.dismissHintsOrClose()
      }

      ColumnLayout {
        id: content
        width: panelScroll.width
        spacing: Style.space(6)

        Row {
          id: toolbarRow
          parent: panelScroll
          anchors.top: parent.top
          anchors.right: parent.right
          spacing: Style.space(8)
          z: 1

          PhosphorIconButton {
            id: statsButton
            iconPath: "M232,208a8,8,0,0,1-8,8H32a8,8,0,0,1-8-8V48a8,8,0,0,1,16,0V156.69l50.34-50.35a8,8,0,0,1,11.32,0L128,132.69,180.69,80H160a8,8,0,0,1,0-16h40a8,8,0,0,1,8,8v40a8,8,0,0,1-16,0V91.31l-58.34,58.35a8,8,0,0,1-11.32,0L96,123.31l-56,56V200H224A8,8,0,0,1,232,208Z"
            tooltipText: root.page === "stats" ? qsTr("Back to timer [H]") : qsTr("Break history [H]")
            selected: root.page === "stats"
            hasCursor: root.keyboardHintsVisible
            foreground: root.foreground
            idleForeground: root.muted
            accent: root.accent
            iconSize: Style.font.icon
            KeyNavigation.tab: settingsButton
            KeyNavigation.backtab: root.page === "stats" ? settingsButton
              : (root.page === "options" ? editSettingsButton
                : (root.delayActionsEnabled ? postpone15Button : breakNowButton))
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.togglePage("stats")

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "H"
            }
          }

          PhosphorIconButton {
            id: settingsButton
            iconPath: "M128,80a48,48,0,1,0,48,48A48.05,48.05,0,0,0,128,80Zm0,80a32,32,0,1,1,32-32A32,32,0,0,1,128,160Zm88-29.84q.06-2.16,0-4.32l14.92-18.64a8,8,0,0,0,1.48-7.06,107.21,107.21,0,0,0-10.88-26.25,8,8,0,0,0-6-3.93l-23.72-2.64q-1.48-1.56-3-3L186,40.54a8,8,0,0,0-3.94-6,107.71,107.71,0,0,0-26.25-10.87,8,8,0,0,0-7.06,1.49L130.16,40Q128,40,125.84,40L107.2,25.11a8,8,0,0,0-7.06-1.48A107.6,107.6,0,0,0,73.89,34.51a8,8,0,0,0-3.93,6L67.32,64.27q-1.56,1.49-3,3L40.54,70a8,8,0,0,0-6,3.94,107.71,107.71,0,0,0-10.87,26.25,8,8,0,0,0,1.49,7.06L40,125.84Q40,128,40,130.16L25.11,148.8a8,8,0,0,0-1.48,7.06,107.21,107.21,0,0,0,10.88,26.25,8,8,0,0,0,6,3.93l23.72,2.64q1.49,1.56,3,3L70,215.46a8,8,0,0,0,3.94,6,107.71,107.71,0,0,0,26.25,10.87,8,8,0,0,0,7.06-1.49L125.84,216q2.16.06,4.32,0l18.64,14.92a8,8,0,0,0,7.06,1.48,107.21,107.21,0,0,0,26.25-10.88,8,8,0,0,0,3.93-6l2.64-23.72q1.56-1.48,3-3L215.46,186a8,8,0,0,0,6-3.94,107.71,107.71,0,0,0,10.87-26.25,8,8,0,0,0-1.49-7.06Zm-16.1-6.5a73.93,73.93,0,0,1,0,8.68,8,8,0,0,0,1.74,5.48l14.19,17.73a91.57,91.57,0,0,1-6.23,15L187,173.11a8,8,0,0,0-5.1,2.64,74.11,74.11,0,0,1-6.14,6.14,8,8,0,0,0-2.64,5.1l-2.51,22.58a91.32,91.32,0,0,1-15,6.23l-17.74-14.19a8,8,0,0,0-5-1.75h-.48a73.93,73.93,0,0,1-8.68,0,8,8,0,0,0-5.48,1.74L100.45,215.8a91.57,91.57,0,0,1-15-6.23L82.89,187a8,8,0,0,0-2.64-5.1,74.11,74.11,0,0,1-6.14-6.14,8,8,0,0,0-5.1-2.64L46.43,170.6a91.32,91.32,0,0,1-6.23-15l14.19-17.74a8,8,0,0,0,1.74-5.48,73.93,73.93,0,0,1,0-8.68,8,8,0,0,0-1.74-5.48L40.2,100.45a91.57,91.57,0,0,1,6.23-15L69,82.89a8,8,0,0,0,5.1-2.64,74.11,74.11,0,0,1,6.14-6.14A8,8,0,0,0,82.89,69L85.4,46.43a91.32,91.32,0,0,1,15-6.23l17.74,14.19a8,8,0,0,0,5.48,1.74,73.93,73.93,0,0,1,8.68,0,8,8,0,0,0,5.48-1.74L155.55,40.2a91.57,91.57,0,0,1,15,6.23L173.11,69a8,8,0,0,0,2.64,5.1,74.11,74.11,0,0,1,6.14,6.14,8,8,0,0,0,5.1,2.64l22.58,2.51a91.32,91.32,0,0,1,6.23,15l-14.19,17.74A8,8,0,0,0,199.87,123.66Z"
            tooltipText: root.page === "options" ? qsTr("Back to timer [O]") : qsTr("Look Elsewhere options [O]")
            selected: root.page === "options"
            hasCursor: root.keyboardHintsVisible
            foreground: root.foreground
            idleForeground: root.muted
            accent: root.accent
            iconSize: Style.font.icon
            KeyNavigation.tab: root.page === "stats" ? statsButton
              : (root.page === "options" ? pauseBreaksButton : breakNowButton)
            KeyNavigation.backtab: statsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.togglePage("options")

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "O"
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.leftMargin: toolbarRow.implicitWidth
          Layout.rightMargin: toolbarRow.implicitWidth
          Layout.topMargin: Style.space(8)
          visible: root.page === "now"
          spacing: Style.space(4)

          Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Style.space(34)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.bottomMargin: Style.space(3)
            Accessible.ignored: true

            BreakIcon {
              anchors.fill: parent
              color: root.accent
            }
          }

          Text {
            Layout.fillWidth: true
            Layout.bottomMargin: -Style.space(10)
            text: root.idlePaused ? qsTr("LookElsewhere is paused") : qsTr("Break starts in")
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
          }

          Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.max(clockRow.implicitWidth, idleClock.implicitWidth)
            Layout.preferredHeight: Math.max(clockRow.implicitHeight, idleClock.implicitHeight)
            Accessible.role: Accessible.StaticText
            Accessible.name: root.idlePaused
              ? qsTr("Idle; focus timer paused")
              : qsTr("Time remaining: %1").arg(root.service ? root.service.remainingText : qsTr("Starting"))

            Row {
              id: clockRow
              anchors.centerIn: parent
              // Remove only the active font's unused colon side-bearing. This
              // preserves natural glyph metrics across Omarchy themes while
              // keeping independently rolling digit columns visually unified.
              spacing: -root.clockSeparatorOverlap
              opacity: root.idlePaused ? 0 : 1
              Accessible.ignored: true

              RollingNumber {
                value: root.remainingMinutesPart
                minimumDigits: 2
                color: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.display * 1.55
                fontWeight: Font.Bold
                reducedMotion: root.service && root.service.config.reducedMotion
                animationActive: root.opened && root.page === "now" && !root.idlePaused
              }

              Text {
                text: ":"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display * 1.55
                font.weight: Font.Bold
                Accessible.ignored: true
              }

              RollingNumber {
                value: root.remainingSecondsPart
                minimumDigits: 2
                color: root.foreground
                fontFamily: root.fontFamily
                fontSize: Style.font.display * 1.55
                fontWeight: Font.Bold
                reducedMotion: root.service && root.service.config.reducedMotion
                animationActive: root.opened && root.page === "now" && !root.idlePaused
              }

              Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            Text {
              id: idleClock
              anchors.centerIn: parent
              text: qsTr("Idle")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display * 1.55
              font.weight: Font.Bold
              opacity: root.idlePaused ? 1 : 0
              Accessible.ignored: true

              Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.leftMargin: toolbarRow.implicitWidth
          Layout.rightMargin: toolbarRow.implicitWidth
          Layout.topMargin: Style.space(8)
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
          Layout.leftMargin: toolbarRow.implicitWidth
          Layout.rightMargin: toolbarRow.implicitWidth
          Layout.topMargin: Style.space(8)
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
            Layout.bottomMargin: root.keyboardHintsVisible ? Style.space(16) : 0
            text: root.manuallyPaused ? qsTr("Resume breaks") : qsTr("Pause breaks")
            enabled: root.service && !root.service.interrupting
            selected: root.manuallyPaused
            hasCursor: root.keyboardHintsVisible
            bordered: true
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: stopButton
            KeyNavigation.backtab: settingsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            onClicked: root.toggleManualPause()

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "P"
              available: pauseBreaksButton.enabled
            }
          }

          Button {
            id: stopButton
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: root.keyboardHintsVisible ? Style.space(16) : 0
            text: qsTr("Stop Look Elsewhere")
            bordered: true
            hasCursor: root.keyboardHintsVisible
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: editSettingsButton
            KeyNavigation.backtab: pauseBreaksButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Stop and disable Look Elsewhere")
            Accessible.onPressAction: clicked()
            onClicked: {
              root.close()
              stopPlugin.running = true
            }

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "⇧D"
            }
          }

          Button {
            id: editSettingsButton
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: root.keyboardHintsVisible ? Style.space(16) : 0
            text: qsTr("Edit settings file")
            bordered: true
            hasCursor: root.keyboardHintsVisible
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            KeyNavigation.tab: statsButton
            KeyNavigation.backtab: stopButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: text
            Accessible.onPressAction: clicked()
            onClicked: {
              root.close()
              settingsEditor.running = true
            }

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "E"
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

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: actionRow.implicitHeight * actionRow.fitScale
            + (root.keyboardHintsVisible ? Style.space(16) : 0)
          Layout.topMargin: -Style.space(3)
          visible: root.page === "now"

          RowLayout {
            id: actionRow
            readonly property real fitScale: Math.min(1,
              (parent.width - Style.space(4)) / Math.max(1, implicitWidth))
            anchors.horizontalCenter: parent.horizontalCenter
            scale: fitScale
            spacing: Style.space(5)

          WeightedButton {
            id: breakNowButton
            label: qsTr("Break now")
            labelWeight: Font.Bold
            selected: true
            hasCursor: root.keyboardHintsVisible
            focusable: true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            horizontalPadding: Style.space(7)
            KeyNavigation.tab: root.delayActionsEnabled ? postpone1Button : statsButton
            KeyNavigation.backtab: settingsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: label
            Accessible.onPressAction: clicked()
            onClicked: root.takeBreakAndClose()

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "B"
            }
          }

          WeightedButton {
            id: postpone1Button
            visible: root.delayActionsVisible
            actionEnabled: root.delayActionsEnabled
            hasCursor: root.keyboardHintsVisible
            tooltipText: root.delayActionsEnabled ? root.snoozeBudgetSummary : ""
            disabledTooltipText: root.delayActionsEnabled ? "" : root.snoozeUnavailableSummary
            label: qsTr("+1m")
            bordered: true
            focusable: root.delayActionsEnabled
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            horizontalPadding: Style.space(6)
            KeyNavigation.tab: postpone5Button
            KeyNavigation.backtab: breakNowButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: root.delayActionsEnabled
              ? qsTr("Snooze next break for 1 minute")
              : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
            Accessible.onPressAction: clicked()
            onClicked: root.postponeAndClose(1)

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "1"
              available: postpone1Button.actionEnabled
            }
          }

          WeightedButton {
            id: postpone5Button
            visible: root.delayActionsVisible
            actionEnabled: root.delayActionsEnabled
            hasCursor: root.keyboardHintsVisible
            tooltipText: root.delayActionsEnabled ? root.snoozeBudgetSummary : ""
            disabledTooltipText: root.delayActionsEnabled ? "" : root.snoozeUnavailableSummary
            label: qsTr("+5m")
            bordered: true
            focusable: root.delayActionsEnabled
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            horizontalPadding: Style.space(6)
            KeyNavigation.tab: postpone15Button
            KeyNavigation.backtab: postpone1Button
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: root.delayActionsEnabled
              ? qsTr("Snooze next break for 5 minutes")
              : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
            Accessible.onPressAction: clicked()
            onClicked: root.postponeAndClose(5)

            KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: "2"
              available: postpone5Button.actionEnabled
            }
          }

            WeightedButton {
              id: postpone15Button
              visible: root.delayActionsVisible
              actionEnabled: root.delayActionsEnabled
              hasCursor: root.keyboardHintsVisible
              tooltipText: root.delayActionsEnabled ? root.snoozeBudgetSummary : ""
              disabledTooltipText: root.delayActionsEnabled ? "" : root.snoozeUnavailableSummary
              label: qsTr("+15m")
              bordered: true
              focusable: root.delayActionsEnabled
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              fontSize: Style.font.bodySmall
              horizontalPadding: Style.space(6)
              KeyNavigation.tab: statsButton
              KeyNavigation.backtab: postpone5Button
              Keys.onEscapePressed: root.dismissHintsOrClose()
              Accessible.role: Accessible.Button
              Accessible.name: root.delayActionsEnabled
                ? qsTr("Snooze next break for 15 minutes")
                : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
              Accessible.onPressAction: clicked()
              onClicked: root.postponeAndClose(15)

              KeyHintBadge {
                visible: root.keyboardHintsVisible
                keyText: "3"
                available: postpone15Button.actionEnabled
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          Layout.topMargin: Style.space(3)
          visible: root.page === "now" && root.delayActionsVisible
          text: root.snoozeAvailabilitySummary
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(2)
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

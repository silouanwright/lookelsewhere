import QtQuick
import QtQuick.Layouts
import qs.Commons
import "Model.js" as Model
import "vendor/qmlpack/oma-ui/Ui" as LookUi

ColumnLayout {
  id: root

  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property bool idlePaused: false
  property bool nextBreakIsLong: false
  property int minutes: 20
  property int seconds: 0
  property string remainingText: qsTr("20 minutes")
  property bool reducedMotion: true
  property bool animationActive: false
  property string recoveryWarning: ""
  property bool delayActionsVisible: true
  property bool delayActionsEnabled: true
  property string snoozeBudgetSummary: ""
  property string snoozeUnavailableSummary: ""
  property string snoozeAvailabilitySummary: qsTr("Snoozes available: 3")
  property bool keyboardHintsVisible: false
  property var shortcuts: ({ breakNow: "B", snooze1: "1", snooze5: "2", snooze15: "3" })
  property real clockSeparatorOverlap: 0
  property Item shortcutsTarget: null
  property Item statsTarget: null
  property Item settingsTarget: null

  readonly property Item breakNowTarget: breakNowButton
  readonly property Item postpone1Target: postpone1Button
  readonly property Item postpone5Target: postpone5Button
  readonly property Item postpone15Target: postpone15Button

  signal breakNowRequested()
  signal postponeRequested(int minutes)
  signal escapeRequested()

  Layout.fillWidth: true
  spacing: Style.space(6)

  ColumnLayout {
    Layout.fillWidth: true
    Layout.leftMargin: root.settingsTarget ? root.settingsTarget.parent.implicitWidth : 0
    Layout.rightMargin: Layout.leftMargin
    Layout.topMargin: Style.space(8)
    spacing: Style.space(4)

    Item {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: Style.space(34)
      Layout.preferredHeight: Layout.preferredWidth
      Layout.bottomMargin: Style.space(3)
      Accessible.ignored: true

      BedIcon {
        anchors.fill: parent
        color: root.accent
      }
    }

    Text {
      Layout.fillWidth: true
      Layout.bottomMargin: -Style.space(10)
      text: root.idlePaused ? qsTr("LookElsewhere is paused")
        : root.nextBreakIsLong ? qsTr("Long break starts in") : qsTr("Break starts in")
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
        ? qsTr("Idle; focus timer paused") : qsTr("Time remaining: %1").arg(root.remainingText)

      Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: -root.clockSeparatorOverlap
        opacity: root.idlePaused ? 0 : 1
        Accessible.ignored: true

        RollingNumber {
          value: root.minutes
          minimumDigits: 2
          color: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.display * 1.55
          fontWeight: Font.Bold
          reducedMotion: root.reducedMotion
          animationActive: root.animationActive && !root.idlePaused
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
          value: root.seconds
          minimumDigits: 2
          color: root.foreground
          fontFamily: root.fontFamily
          fontSize: Style.font.display * 1.55
          fontWeight: Font.Bold
          reducedMotion: root.reducedMotion
          animationActive: root.animationActive && !root.idlePaused
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

  Text {
    Layout.fillWidth: true
    visible: root.recoveryWarning !== ""
    text: root.recoveryWarning
    color: Color.urgent
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: actionRow.implicitHeight * actionRow.fitScale
    Layout.topMargin: -Style.space(3)

    RowLayout {
      id: actionRow
      readonly property real fitScale: Math.min(1, (parent.width - Style.space(4)) / Math.max(1, implicitWidth))
      anchors.horizontalCenter: parent.horizontalCenter
      transformOrigin: Item.Top
      scale: fitScale
      spacing: Style.space(5)

      LookUi.WeightedButton {
        id: breakNowButton
        label: qsTr("Break now")
        labelWeight: Font.Bold
        selected: true
        focusable: true
        foreground: root.foreground
        accent: root.accent
        fontFamily: root.fontFamily
        fontSize: Style.font.bodySmall
        horizontalPadding: Style.space(7)
        KeyNavigation.tab: root.delayActionsEnabled ? postpone1Button : root.shortcutsTarget
        KeyNavigation.backtab: root.settingsTarget
        KeyNavigation.up: root.shortcutsTarget
        KeyNavigation.right: root.delayActionsEnabled ? postpone1Button : root.settingsTarget
        Keys.onEscapePressed: root.escapeRequested()
        Accessible.role: Accessible.Button
        Accessible.name: label
        Accessible.onPressAction: clicked()
        onClicked: root.breakNowRequested()

        LookUi.KeyHintBadge {
          visible: root.keyboardHintsVisible
          keyText: Model.panelShortcutLabel(root.shortcuts.breakNow)
          centerOnCorner: true
        }
      }

      LookUi.WeightedButton {
        id: postpone1Button
        visible: root.delayActionsVisible
        actionEnabled: root.delayActionsEnabled
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
        KeyNavigation.left: breakNowButton
        KeyNavigation.right: postpone5Button
        KeyNavigation.up: root.statsTarget
        Keys.onEscapePressed: root.escapeRequested()
        Accessible.role: Accessible.Button
        Accessible.name: root.delayActionsEnabled
          ? qsTr("Snooze next break for 1 minute")
          : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
        Accessible.onPressAction: clicked()
        onClicked: root.postponeRequested(1)

        LookUi.KeyHintBadge {
          visible: root.keyboardHintsVisible
          keyText: Model.panelShortcutLabel(root.shortcuts.snooze1)
          available: postpone1Button.actionEnabled
          centerOnCorner: true
        }
      }

      LookUi.WeightedButton {
        id: postpone5Button
        visible: root.delayActionsVisible
        actionEnabled: root.delayActionsEnabled
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
        KeyNavigation.left: postpone1Button
        KeyNavigation.right: postpone15Button
        KeyNavigation.up: root.statsTarget
        Keys.onEscapePressed: root.escapeRequested()
        Accessible.role: Accessible.Button
        Accessible.name: root.delayActionsEnabled
          ? qsTr("Snooze next break for 5 minutes")
          : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
        Accessible.onPressAction: clicked()
        onClicked: root.postponeRequested(5)

        LookUi.KeyHintBadge {
          visible: root.keyboardHintsVisible
          keyText: Model.panelShortcutLabel(root.shortcuts.snooze5)
          available: postpone5Button.actionEnabled
          centerOnCorner: true
        }
      }

      LookUi.WeightedButton {
        id: postpone15Button
        visible: root.delayActionsVisible
        actionEnabled: root.delayActionsEnabled
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
        KeyNavigation.tab: root.shortcutsTarget
        KeyNavigation.backtab: postpone5Button
        KeyNavigation.left: postpone5Button
        KeyNavigation.right: root.settingsTarget
        KeyNavigation.up: root.settingsTarget
        Keys.onEscapePressed: root.escapeRequested()
        Accessible.role: Accessible.Button
        Accessible.name: root.delayActionsEnabled
          ? qsTr("Snooze next break for 15 minutes")
          : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
        Accessible.onPressAction: clicked()
        onClicked: root.postponeRequested(15)

        LookUi.KeyHintBadge {
          visible: root.keyboardHintsVisible
          keyText: Model.panelShortcutLabel(root.shortcuts.snooze15)
          available: postpone15Button.actionEnabled
          centerOnCorner: true
        }
      }
    }
  }

  Text {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(3)
    visible: root.delayActionsVisible
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

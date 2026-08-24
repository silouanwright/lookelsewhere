import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "Ui" as LookUi

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
  readonly property bool idlePaused: service && service.idlePauseActive
  readonly property bool delayActionsVisible: !manuallyPaused && service
  readonly property bool delayActionsEnabled: !!delayActionsVisible && !!service.canPostpone
  readonly property bool shortcutsActive: opened
  readonly property bool numberEditorActive: root.page === "options" && settingsPage.editorActive
  readonly property bool dropdownOpen: root.page === "options" && settingsPage.dropdownOpen
  readonly property var shortcuts: Model.panelShortcuts(settings)
  readonly property bool keyboardHintsVisible: !!(settings && settings.showKeyboardHints === true)
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
    if (service && Model.canTogglePause(service.phase)) service.togglePause()
  }
  function persistSettings(values) {
    var entry = { id: root.moduleName }
    for (var existing in root.settings) if (existing !== "id") entry[existing] = root.settings[existing]
    for (var key in values) entry[key] = values[key]

    root.settings = entry
    if (root.hostWidget && "settings" in root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }
  function togglePage(name) { page = page === name ? "now" : name }
  function toggleKeyboardHints() {
    persistSettings({ showKeyboardHints: !keyboardHintsVisible })
  }
  function dismissHintsOrClose() { close() }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()
  onPageChanged: if (opened) Qt.callLater(function() {
    if (root.page === "options") settingsPage.focusInitial()
    else neutralFocus.forceActiveFocus()
  })
  onOpenedChanged: if (opened) {
    page = "now"
    settingsPage.reset()
  }

  KeyboardPanel {
    id: popup
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    // The control surface belongs spatially to the bed button. Warning and
    // break surfaces are separate and intentionally centered by Overlay.qml.
    centerOnBar: false
    focusTarget: root.page === "options" ? settingsPage.initialFocusTarget : neutralFocus
    contentWidth: popup.fittedContentWidth(Style.space(root.page === "options" ? 440 : 260))
    contentHeight: popup.fittedContentHeight(content.implicitHeight)

    // Window-local mnemonics must live in the popup's item tree so Qt can
    // associate WindowShortcut with the layer-shell window that owns focus.
    Item {
      width: 0
      height: 0

      Shortcut { sequence: root.shortcuts.breakNow; context: Qt.WindowShortcut; enabled: root.shortcutsActive; onActivated: root.takeBreakAndClose() }
      Shortcut { sequence: root.shortcuts.snooze1; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.delayActionsEnabled; onActivated: root.postponeAndClose(1) }
      Shortcut { sequence: root.shortcuts.snooze5; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.delayActionsEnabled; onActivated: root.postponeAndClose(5) }
      Shortcut { sequence: root.shortcuts.snooze15; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.delayActionsEnabled; onActivated: root.postponeAndClose(15) }
      Shortcut { sequence: root.shortcuts.pause; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.service && Model.canTogglePause(root.service.phase); onActivated: root.toggleManualPause() }
      Shortcut { sequence: root.shortcuts.history; context: Qt.WindowShortcut; enabled: root.shortcutsActive; onActivated: root.togglePage("stats") }
      Shortcut { sequence: root.shortcuts.options; context: Qt.WindowShortcut; enabled: root.shortcutsActive; onActivated: root.togglePage("options") }
      Shortcut { sequence: root.shortcuts.edit; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: { root.close(); settingsEditor.running = true } }
      Shortcut { sequence: root.shortcuts.generalTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: settingsPage.settingsTab = "general" }
      Shortcut { sequence: root.shortcuts.breaksTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: settingsPage.settingsTab = "breaks" }
      Shortcut { sequence: root.shortcuts.contextTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: settingsPage.settingsTab = "context" }
      Shortcut { sequence: root.shortcuts.experienceTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: settingsPage.settingsTab = "experience" }
      Shortcut {
        sequence: root.shortcuts.close
        context: Qt.WindowShortcut
        enabled: root.shortcutsActive && !root.numberEditorActive && !root.dropdownOpen
        onActivated: root.close()
      }
      Shortcut { sequence: root.shortcuts.hints; context: Qt.WindowShortcut; enabled: root.shortcutsActive; onActivated: root.toggleKeyboardHints() }
    }

    Item {
      id: neutralFocus
      width: 0
      height: 0
      focus: true
      KeyNavigation.tab: shortcutsButton
      KeyNavigation.backtab: root.page === "stats" ? settingsButton
        : (root.delayActionsEnabled ? nowView.postpone15Target : nowView.breakNowTarget)
      Keys.onEscapePressed: root.dismissHintsOrClose()
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Down || event.text === "j") {
          if (root.page === "now") nowView.breakNowTarget.forceActiveFocus()
          else if (root.page === "options") settingsPage.focusInitial()
          else shortcutsButton.forceActiveFocus()
          event.accepted = true
        } else if (event.key === Qt.Key_Right || event.text === "l") {
          settingsButton.forceActiveFocus(); event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left
                   || event.text === "k" || event.text === "h") {
          shortcutsButton.forceActiveFocus(); event.accepted = true
        }
      }
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.page !== "options"
        || root.numberEditorActive
        || root.dropdownOpen
        || settingsPage.initialFocusTarget.activeFocus
        || shortcutsButton.activeFocus
        || statsButton.activeFocus
        || settingsButton.activeFocus
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) settingsPage.moveCursor(dy)
      }
      onActivateRequested: settingsPage.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { settingsPage.moveCursor(direction) }

      Item {
        id: optionsFocus
        width: 0
        height: 0
        focus: true
      }

      ScrollView {
        id: panelScroll
        anchors.fill: parent
        clip: true
        Keys.priority: Keys.BeforeItem
        Keys.onEscapePressed: function(event) {
          if (!root.numberEditorActive) return
          optionsFocus.forceActiveFocus()
          event.accepted = true
        }
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: content.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

      ColumnLayout {
        id: content
        width: panelScroll.availableWidth
        spacing: Style.space(6)

        Item {
          id: toolbarSurface
          parent: panelScroll
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: Math.max(shortcutsButton.implicitHeight, toolbarRow.implicitHeight) + Style.space(12)
          z: 2

        }

        LookUi.PhosphorIconButton {
          id: shortcutsButton
          parent: toolbarSurface
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          z: 1
          iconPath: "M140,180a12,12,0,1,1-12-12A12,12,0,0,1,140,180ZM128,72c-22.06,0-40,16.15-40,36v4a8,8,0,0,0,16,0v-4c0-11,10.77-20,24-20s24,9,24,20-10.77,20-24,20a8,8,0,0,0-8,8v8a8,8,0,0,0,16,0v-.72c18.24-3.35,32-17.9,32-35.28C168,88.15,150.06,72,128,72Zm104,56A104,104,0,1,1,128,24,104.11,104.11,0,0,1,232,128Zm-16,0a88,88,0,1,0-88,88A88.1,88.1,0,0,0,216,128Z"
          tooltipText: qsTr("Keyboard shortcuts [%1]").arg(root.shortcuts.hints)
          foreground: root.foreground
          idleForeground: root.muted
          accent: root.accent
          iconSize: Style.font.icon
          KeyNavigation.tab: statsButton
          KeyNavigation.backtab: root.page === "stats" ? settingsButton
            : (root.page === "options" ? settingsPage.finalFocusTarget
              : (root.delayActionsEnabled ? nowView.postpone15Target : nowView.breakNowTarget))
          KeyNavigation.right: statsButton
          KeyNavigation.down: root.page === "options" ? settingsPage.initialFocusTarget
            : (root.page === "now" ? nowView.breakNowTarget : shortcutsButton)
          Keys.onEscapePressed: root.dismissHintsOrClose()
          Accessible.role: Accessible.Button
          Accessible.name: qsTr("Toggle keyboard shortcut hints")
          Accessible.onPressAction: clicked()
          onClicked: root.toggleKeyboardHints()

          LookUi.KeyHintBadge {
            visible: root.keyboardHintsVisible
            keyText: Model.panelShortcutLabel(root.shortcuts.hints)
          }
        }

        Row {
          id: toolbarRow
          parent: toolbarSurface
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)
          z: 1

          LookUi.PhosphorIconButton {
            id: statsButton
            iconPath: "M232,208a8,8,0,0,1-8,8H32a8,8,0,0,1-8-8V48a8,8,0,0,1,16,0V156.69l50.34-50.35a8,8,0,0,1,11.32,0L128,132.69,180.69,80H160a8,8,0,0,1,0-16h40a8,8,0,0,1,8,8v40a8,8,0,0,1-16,0V91.31l-58.34,58.35a8,8,0,0,1-11.32,0L96,123.31l-56,56V200H224A8,8,0,0,1,232,208Z"
            tooltipText: root.page === "stats"
              ? qsTr("Back to timer [%1]").arg(root.shortcuts.history)
              : qsTr("Break history [%1]").arg(root.shortcuts.history)
            selected: root.page === "stats"
            foreground: root.foreground
            idleForeground: root.muted
            accent: root.accent
            iconSize: Style.font.icon
            KeyNavigation.tab: settingsButton
            KeyNavigation.backtab: shortcutsButton
            KeyNavigation.left: shortcutsButton
            KeyNavigation.right: settingsButton
            KeyNavigation.down: root.page === "options" ? settingsPage.initialFocusTarget
              : (root.page === "now" ? nowView.breakNowTarget : statsButton)
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.togglePage("stats")

            LookUi.KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: Model.panelShortcutLabel(root.shortcuts.history)
            }
          }

          LookUi.PhosphorIconButton {
            id: settingsButton
            iconPath: "M128,80a48,48,0,1,0,48,48A48.05,48.05,0,0,0,128,80Zm0,80a32,32,0,1,1,32-32A32,32,0,0,1,128,160Zm88-29.84q.06-2.16,0-4.32l14.92-18.64a8,8,0,0,0,1.48-7.06,107.21,107.21,0,0,0-10.88-26.25,8,8,0,0,0-6-3.93l-23.72-2.64q-1.48-1.56-3-3L186,40.54a8,8,0,0,0-3.94-6,107.71,107.71,0,0,0-26.25-10.87,8,8,0,0,0-7.06,1.49L130.16,40Q128,40,125.84,40L107.2,25.11a8,8,0,0,0-7.06-1.48A107.6,107.6,0,0,0,73.89,34.51a8,8,0,0,0-3.93,6L67.32,64.27q-1.56,1.49-3,3L40.54,70a8,8,0,0,0-6,3.94,107.71,107.71,0,0,0-10.87,26.25,8,8,0,0,0,1.49,7.06L40,125.84Q40,128,40,130.16L25.11,148.8a8,8,0,0,0-1.48,7.06,107.21,107.21,0,0,0,10.88,26.25,8,8,0,0,0,6,3.93l23.72,2.64q1.49,1.56,3,3L70,215.46a8,8,0,0,0,3.94,6,107.71,107.71,0,0,0,26.25,10.87,8,8,0,0,0,7.06-1.49L125.84,216q2.16.06,4.32,0l18.64,14.92a8,8,0,0,0,7.06,1.48,107.21,107.21,0,0,0,26.25-10.88,8,8,0,0,0,3.93-6l2.64-23.72q1.56-1.48,3-3L215.46,186a8,8,0,0,0,6-3.94,107.71,107.71,0,0,0,10.87-26.25,8,8,0,0,0-1.49-7.06Zm-16.1-6.5a73.93,73.93,0,0,1,0,8.68,8,8,0,0,0,1.74,5.48l14.19,17.73a91.57,91.57,0,0,1-6.23,15L187,173.11a8,8,0,0,0-5.1,2.64,74.11,74.11,0,0,1-6.14,6.14,8,8,0,0,0-2.64,5.1l-2.51,22.58a91.32,91.32,0,0,1-15,6.23l-17.74-14.19a8,8,0,0,0-5-1.75h-.48a73.93,73.93,0,0,1-8.68,0,8,8,0,0,0-5.48,1.74L100.45,215.8a91.57,91.57,0,0,1-15-6.23L82.89,187a8,8,0,0,0-2.64-5.1,74.11,74.11,0,0,1-6.14-6.14,8,8,0,0,0-5.1-2.64L46.43,170.6a91.32,91.32,0,0,1-6.23-15l14.19-17.74a8,8,0,0,0,1.74-5.48,73.93,73.93,0,0,1,0-8.68,8,8,0,0,0-1.74-5.48L40.2,100.45a91.57,91.57,0,0,1,6.23-15L69,82.89a8,8,0,0,0,5.1-2.64,74.11,74.11,0,0,1,6.14-6.14A8,8,0,0,0,82.89,69L85.4,46.43a91.32,91.32,0,0,1,15-6.23l17.74,14.19a8,8,0,0,0,5.48,1.74,73.93,73.93,0,0,1,8.68,0,8,8,0,0,0,5.48-1.74L155.55,40.2a91.57,91.57,0,0,1,15,6.23L173.11,69a8,8,0,0,0,2.64,5.1,74.11,74.11,0,0,1,6.14,6.14,8,8,0,0,0,5.1,2.64l22.58,2.51a91.32,91.32,0,0,1,6.23,15l-14.19,17.74A8,8,0,0,0,199.87,123.66Z"
            displayIconPath: root.page === "options"
              ? "M224,128a8,8,0,0,1-8,8H59.31l58.35,58.34a8,8,0,0,1-11.32,11.32l-72-72a8,8,0,0,1,0-11.32l72-72a8,8,0,0,1,11.32,11.32L59.31,120H216A8,8,0,0,1,224,128Z"
              : iconPath
            tooltipText: root.page === "options"
              ? qsTr("Back to timer [%1]").arg(root.shortcuts.options)
              : qsTr("LookElsewhere options [%1]").arg(root.shortcuts.options)
            selected: false
            foreground: root.foreground
            idleForeground: root.muted
            accent: root.accent
            iconSize: Style.font.icon
            KeyNavigation.tab: root.page === "stats" ? shortcutsButton
              : (root.page === "options" ? settingsPage.initialFocusTarget : nowView.breakNowTarget)
            KeyNavigation.backtab: statsButton
            KeyNavigation.left: statsButton
            KeyNavigation.right: shortcutsButton
            KeyNavigation.down: root.page === "options" ? settingsPage.initialFocusTarget
              : (root.page === "now" ? nowView.breakNowTarget : settingsButton)
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: tooltipText
            Accessible.onPressAction: clicked()
            onClicked: root.togglePage("options")

            LookUi.KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: Model.panelShortcutLabel(root.shortcuts.options)
            }
          }
        }

        PanelNowView {
          id: nowView
          visible: root.page === "now"
          foreground: root.foreground
          muted: root.muted
          accent: root.accent
          fontFamily: root.fontFamily
          idlePaused: root.idlePaused
          nextBreakIsLong: root.service && root.service.nextBreakIsLong
          minutes: root.remainingMinutesPart
          seconds: root.remainingSecondsPart
          remainingText: root.service ? root.service.remainingText : qsTr("Starting")
          reducedMotion: root.service && root.service.config.reducedMotion
          animationActive: root.opened && root.page === "now"
          recoveryWarning: root.service ? root.service.recoveryWarning : ""
          delayActionsVisible: root.delayActionsVisible
          delayActionsEnabled: root.delayActionsEnabled
          snoozeBudgetSummary: root.snoozeBudgetSummary
          snoozeUnavailableSummary: root.snoozeUnavailableSummary
          snoozeAvailabilitySummary: root.snoozeAvailabilitySummary
          keyboardHintsVisible: root.keyboardHintsVisible
          shortcuts: root.shortcuts
          clockSeparatorOverlap: root.clockSeparatorOverlap
          shortcutsTarget: shortcutsButton
          statsTarget: statsButton
          settingsTarget: settingsButton
          onBreakNowRequested: root.takeBreakAndClose()
          onPostponeRequested: function(minutes) { root.postponeAndClose(minutes) }
          onEscapeRequested: root.dismissHintsOrClose()
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

        SettingsPage {
          id: settingsPage
          visible: root.page === "options"
          active: root.opened && visible
          service: root.service
          settings: root.settings
          shortcuts: root.shortcuts
          keyboardHintsVisible: root.keyboardHintsVisible
          manuallyPaused: root.manuallyPaused
          foreground: root.foreground
          muted: root.muted
          accent: root.accent
          fontFamily: root.fontFamily
          focusProxy: optionsFocus
          settingsButtonTarget: settingsButton
          shortcutsButtonTarget: shortcutsButton
          scrollFlickable: panelScroll.contentItem
          topInset: toolbarSurface.height
          onPersistRequested: function(values) { root.persistSettings(values) }
          onPauseRequested: root.toggleManualPause()
          onEditRequested: {
            root.close()
            settingsEditor.running = true
          }
          onCloseRequested: root.close()
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

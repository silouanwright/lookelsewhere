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
  property string settingsTab: "general"
  property int optionsCursorIndex: 0
  property bool optionsCursorActive: false

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
  readonly property bool numberEditorActive: root.page === "options"
    && (focusMinutesField.field.activeFocus
      || focusMinutesField.field.contentItem.activeFocus
      || shortBreakField.field.activeFocus
      || shortBreakField.field.contentItem.activeFocus
      || longBreakEveryField.editorActive
      || longBreakSecondsField.editorActive
      || snoozeBudgetField.editorActive
      || maximumDelayField.editorActive
      || soundVolumeField.editorActive)
  readonly property bool dropdownOpen: enforcementDropdown.popupOpen
    || officeStartDropdown.popupOpen || officeEndDropdown.popupOpen
    || outputModeDropdown.popupOpen || displayModeDropdown.popupOpen
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
  function clockOptions() {
    var values = []
    for (var halfHour = 0; halfHour < 48; halfHour++) {
      var hour = Math.floor(halfHour / 2)
      var minute = halfHour % 2 ? "30" : "00"
      var value = (hour < 10 ? "0" : "") + hour + ":" + minute
      values.push({ value: value, label: value })
    }
    return values
  }
  function dismissHintsOrClose() { close() }
  function optionsTabStart() {
    return settingsTab === "general" ? 0
      : settingsTab === "context" ? 5
      : settingsTab === "breaks" ? 10 : 17
  }
  function optionsTabEnd() {
    return settingsTab === "general" ? 4
      : settingsTab === "context" ? 9
      : settingsTab === "breaks" ? 16 : 24
  }
  function setOptionsCursor(index) {
    optionsCursorIndex = Math.max(optionsTabStart(), Math.min(optionsTabEnd(), index))
    optionsCursorActive = true
    var targets = [pauseBreaksButton, editSettingsButton,
      officeHoursRow, officeStartDropdown, officeEndDropdown,
      idleDetectionRow, fullscreenDetectionRow, mediaDetectionRow,
      microphoneDetectionRow, dictationDetectionRow, focusMinutesField,
      shortBreakField, longBreakEveryField, longBreakSecondsField,
      snoozeBudgetField, maximumDelayField, enforcementDropdown,
      reduceMotionRow, soundRow, soundVolumeField, startSoundRow,
      completionSoundRow, outputModeDropdown, displayModeDropdown,
      keyboardHintRow]
    ensureOptionsCursorVisible(targets[optionsCursorIndex])
  }
  function moveOptionsCursor(delta) {
    if (optionsCursorActive && delta < 0 && optionsCursorIndex <= optionsTabStart()) {
      optionsCursorActive = false
      settingsTabs.forceActiveFocus()
      ensureOptionsCursorVisible(settingsTabs)
      return
    }
    setOptionsCursor(optionsCursorActive ? optionsCursorIndex + delta : optionsTabStart())
  }
  function activateOptionsCursor() {
    if (!optionsCursorActive) { setOptionsCursor(0); return }
    switch (optionsCursorIndex) {
    case 0: if (pauseBreaksButton.enabled) pauseBreaksButton.clicked(); break
    case 1: editSettingsButton.clicked(); break
    case 2: officeHoursRow.clicked(); break
    case 3: officeStartDropdown.toggle(); break
    case 4: officeEndDropdown.toggle(); break
    case 5: idleDetectionRow.clicked(); break
    case 6: fullscreenDetectionRow.clicked(); break
    case 7: mediaDetectionRow.clicked(); break
    case 8: microphoneDetectionRow.clicked(); break
    case 9: dictationDetectionRow.clicked(); break
    case 10: focusMinutesField.field.forceActiveFocus(); break
    case 11: shortBreakField.field.forceActiveFocus(); break
    case 12: longBreakEveryField.focusEditor(); break
    case 13: longBreakSecondsField.focusEditor(); break
    case 14: snoozeBudgetField.focusEditor(); break
    case 15: maximumDelayField.focusEditor(); break
    case 16: enforcementDropdown.toggle(); break
    case 17: reduceMotionRow.clicked(); break
    case 18: soundRow.clicked(); break
    case 19: soundVolumeField.focusEditor(); break
    case 20: startSoundRow.clicked(); break
    case 21: completionSoundRow.clicked(); break
    case 22: outputModeDropdown.toggle(); break
    case 23: displayModeDropdown.toggle(); break
    case 24: keyboardHintRow.clicked(); break
    }
  }
  function ensureOptionsCursorVisible(item) {
    if (!item || !panelScroll || !panelScroll.contentItem) return
    var flick = panelScroll.contentItem
    if (flick.contentY === undefined) return
    var point = item.mapToItem(flick.contentItem || flick, 0, 0)
    var margin = Style.space(6)
    if (point.y < flick.contentY + margin)
      flick.contentY = Math.max(0, point.y - margin)
    else if (point.y + item.height > flick.contentY + flick.height - margin)
      flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height),
        point.y + item.height + margin - flick.height)
  }
  onSettingsChanged: syncSettings()
  onServiceChanged: syncSettings()
  onPageChanged: if (opened) Qt.callLater(function() {
    if (root.page === "options") settingsTabs.forceActiveFocus()
    else neutralFocus.forceActiveFocus()
  })
  onOpenedChanged: if (opened) {
    page = "now"
    settingsTab = "general"
    optionsCursorActive = false
    optionsCursorIndex = 0
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
    focusTarget: root.page === "options" ? settingsTabs : neutralFocus
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
      Shortcut { sequence: root.shortcuts.generalTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: root.settingsTab = "general" }
      Shortcut { sequence: root.shortcuts.breaksTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: root.settingsTab = "breaks" }
      Shortcut { sequence: root.shortcuts.contextTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: root.settingsTab = "context" }
      Shortcut { sequence: root.shortcuts.experienceTab; context: Qt.WindowShortcut; enabled: root.shortcutsActive && root.page === "options"; onActivated: root.settingsTab = "experience" }
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
        : (root.delayActionsEnabled ? postpone15Button : breakNowButton)
      Keys.onEscapePressed: root.dismissHintsOrClose()
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Down || event.text === "j") {
          if (root.page === "now") breakNowButton.forceActiveFocus()
          else if (root.page === "options") settingsTabs.forceActiveFocus()
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
        || settingsTabs.activeFocus
        || shortcutsButton.activeFocus
        || statsButton.activeFocus
        || settingsButton.activeFocus
      onMoveRequested: function(dx, dy) {
        if (dy !== 0) root.moveOptionsCursor(dy)
      }
      onActivateRequested: root.activateOptionsCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.moveOptionsCursor(direction) }

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
            : (root.page === "options" ? editSettingsButton
              : (root.delayActionsEnabled ? postpone15Button : breakNowButton))
          KeyNavigation.right: statsButton
          KeyNavigation.down: root.page === "options" ? settingsTabs
            : (root.page === "now" ? breakNowButton : shortcutsButton)
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
            KeyNavigation.down: root.page === "options" ? settingsTabs
              : (root.page === "now" ? breakNowButton : statsButton)
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
              : (root.page === "options" ? settingsTabs : breakNowButton)
            KeyNavigation.backtab: statsButton
            KeyNavigation.left: statsButton
            KeyNavigation.right: shortcutsButton
            KeyNavigation.down: root.page === "options" ? settingsTabs
              : (root.page === "now" ? breakNowButton : settingsButton)
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
            text: root.idlePaused ? qsTr("LookElsewhere is paused")
              : root.service && root.service.nextBreakIsLong ? qsTr("Long break starts in")
              : qsTr("Break starts in")
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
          Layout.topMargin: Style.space(8)
          visible: root.page === "options"
          spacing: Style.space(10)

          LookUi.SettingsTabBar {
            id: settingsTabs
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: toolbarSurface.height + Style.space(8)
            options: [
              { value: "general", label: qsTr("General"), key: Model.panelShortcutLabel(root.shortcuts.generalTab) },
              { value: "breaks", label: qsTr("Breaks"), key: Model.panelShortcutLabel(root.shortcuts.breaksTab) },
              { value: "context", label: qsTr("Context"), key: Model.panelShortcutLabel(root.shortcuts.contextTab) },
              { value: "experience", label: qsTr("Experience"), key: Model.panelShortcutLabel(root.shortcuts.experienceTab) }
            ]
            value: root.settingsTab
            hintsVisible: root.keyboardHintsVisible
            foreground: root.foreground
            background: Color.popups.background
            accent: root.accent
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            KeyNavigation.tab: root.settingsTab === "general" ? pauseBreaksButton
              : root.settingsTab === "context" ? idleDetectionRow
              : root.settingsTab === "breaks" ? focusMinutesField.field
              : reduceMotionRow
            Keys.onEscapePressed: root.dismissHintsOrClose()
            onDownRequested: {
              optionsFocus.forceActiveFocus()
              root.setOptionsCursor(root.optionsTabStart())
            }
            onUpRequested: settingsButton.forceActiveFocus()
            onChanged: function(next) {
              root.settingsTab = next
              root.optionsCursorActive = false
              panelScroll.contentItem.contentY = 0
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            visible: root.settingsTab === "general"

          LookUi.SectionHeader {
            Layout.fillWidth: true
            label: qsTr("App controls")
            foreground: root.muted
            fontFamily: root.fontFamily
          }

          LookUi.ToggleSettingRow {
            id: pauseBreaksButton
            Layout.fillWidth: true
            label: qsTr("Break reminders")
            description: qsTr("Temporarily pause break reminders")
            checked: !!root.service && !root.manuallyPaused
            enabled: !!root.service && Model.canTogglePause(root.service.phase)
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 0
            onHovered: function(on) { if (on) root.setOptionsCursor(0) }
            KeyNavigation.tab: editSettingsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            onClicked: root.toggleManualPause()

            LookUi.KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: Model.panelShortcutLabel(root.shortcuts.pause)
              available: pauseBreaksButton.enabled
              x: parent.width - width
              y: -height / 2
            }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(editSettingsLabels.implicitHeight, editSettingsButton.implicitHeight)

            Column {
              id: editSettingsLabels
              anchors.left: parent.left
              anchors.right: editSettingsButton.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)
              Text { width: parent.width; text: qsTr("Omarchy configuration"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
              Text { width: parent.width; text: qsTr("Open the Omarchy Shell configuration file"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
            }

            LookUi.WeightedButton {
              id: editSettingsButton
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              label: qsTr("Open file")
              labelWeight: Font.DemiBold
              bordered: true
              focusable: true
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 1
              onHovered: function(on) { if (on) root.setOptionsCursor(1) }
              KeyNavigation.backtab: pauseBreaksButton
              Keys.onEscapePressed: root.dismissHintsOrClose()
              Accessible.role: Accessible.Button
              Accessible.name: qsTr("Open Omarchy Shell configuration file")
              Accessible.onPressAction: clicked()
              onClicked: {
                root.close()
                settingsEditor.running = true
              }

            }

            LookUi.KeyHintBadge {
              visible: root.keyboardHintsVisible
              keyText: Model.panelShortcutLabel(root.shortcuts.edit)
              x: parent.width - width
              y: editSettingsButton.y - height / 2
            }
          }

          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            visible: root.settingsTab === "general"

          LookUi.SectionHeader {
            Layout.fillWidth: true
            Layout.topMargin: Style.space(8)
            label: qsTr("Office hours")
            foreground: root.muted
            fontFamily: root.fontFamily
          }

          LookUi.ToggleSettingRow {
            id: officeHoursRow
            Layout.fillWidth: true
            label: qsTr("Use office hours")
            description: qsTr("Show break reminders only during these hours")
            checked: root.settings && root.settings.officeHoursEnabled === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 2
            onHovered: function(on) { if (on) root.setOptionsCursor(2) }
            onClicked: root.persistSettings({ officeHoursEnabled: !checked })
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.DropdownSettingRow {
            id: officeStartDropdown
            Layout.fillWidth: true
            label: qsTr("Starts")
            description: qsTr("Beginning of the active schedule")
            value: root.settings && root.settings.officeStart !== undefined ? String(root.settings.officeStart) : "08:00"
            options: root.clockOptions()
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 3
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(3) }
            onPopupClosed: if (root.opened && root.page === "options") Qt.callLater(function() { optionsFocus.forceActiveFocus() })
            onChanged: function(next) { root.persistSettings({ officeStart: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.DropdownSettingRow {
            id: officeEndDropdown
            Layout.fillWidth: true
            label: qsTr("Ends")
            description: qsTr("End of the active schedule; overnight is supported")
            value: root.settings && root.settings.officeEnd !== undefined ? String(root.settings.officeEnd) : "18:00"
            options: root.clockOptions()
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 4
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(4) }
            onPopupClosed: if (root.opened && root.page === "options") Qt.callLater(function() { optionsFocus.forceActiveFocus() })
            onChanged: function(next) { root.persistSettings({ officeEnd: next }) }
          }

          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            visible: root.settingsTab === "context"

          LookUi.SectionHeader {
            Layout.fillWidth: true
            Layout.topMargin: Style.space(8)
            label: qsTr("Smart context")
            foreground: root.muted
            fontFamily: root.fontFamily
          }

          LookUi.ToggleSettingRow {
            id: idleDetectionRow
            Layout.fillWidth: true
            label: qsTr("Pause while idle")
            description: qsTr("Count active screen time instead of time away")
            checked: !root.settings || root.settings.idleDetection === undefined || root.settings.idleDetection === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 5
            onHovered: function(on) { if (on) root.setOptionsCursor(5) }
            onClicked: root.persistSettings({ idleDetection: !checked })
          }
          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }
          LookUi.ToggleSettingRow {
            id: fullscreenDetectionRow
            Layout.fillWidth: true
            label: qsTr("Protect fullscreen work")
            description: qsTr("Delay a due break while fullscreen")
            checked: !root.settings || root.settings.fullscreenDetection === undefined || root.settings.fullscreenDetection === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 6
            onHovered: function(on) { if (on) root.setOptionsCursor(6) }
            onClicked: root.persistSettings({ fullscreenDetection: !checked })
          }
          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }
          LookUi.ToggleSettingRow {
            id: mediaDetectionRow
            Layout.fillWidth: true
            label: qsTr("Protect focused video")
            description: qsTr("Delay while the focused app is playing media")
            checked: !root.settings || root.settings.mediaDetection === undefined || root.settings.mediaDetection === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 7
            onHovered: function(on) { if (on) root.setOptionsCursor(7) }
            onClicked: root.persistSettings({ mediaDetection: !checked })
          }
          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }
          LookUi.ToggleSettingRow {
            id: microphoneDetectionRow
            Layout.fillWidth: true
            label: qsTr("Protect microphone use")
            description: qsTr("Delay during calls without recording audio")
            checked: !root.settings || root.settings.microphoneDetection === undefined || root.settings.microphoneDetection === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 8
            onHovered: function(on) { if (on) root.setOptionsCursor(8) }
            onClicked: root.persistSettings({ microphoneDetection: !checked })
          }
          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }
          LookUi.ToggleSettingRow {
            id: dictationDetectionRow
            Layout.fillWidth: true
            label: qsTr("Protect dictation")
            description: qsTr("Delay while Omarchy dictation is active")
            checked: !root.settings || root.settings.dictationDetection === undefined || root.settings.dictationDetection === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 9
            onHovered: function(on) { if (on) root.setOptionsCursor(9) }
            onClicked: root.persistSettings({ dictationDetection: !checked })
          }

          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            visible: root.settingsTab === "breaks"

          LookUi.SectionHeader {
            Layout.fillWidth: true
            Layout.topMargin: Style.space(8)
            label: qsTr("Break schedule")
            foreground: root.muted
            fontFamily: root.fontFamily
          }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(focusLabels.implicitHeight, focusMinutesField.implicitHeight)

            Column {
              id: focusLabels
              anchors.left: parent.left
              anchors.right: focusMinutesField.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)
              Text { width: parent.width; text: qsTr("Focus interval"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
              Text { width: parent.width; text: qsTr("Minutes of active screen time between breaks"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
            }

            NumberField {
              id: focusMinutesField
              width: Style.space(72)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              value: root.settings && root.settings.focusMinutes !== undefined ? Number(root.settings.focusMinutes) : 20
              from: 1
              to: 180
              fieldWidth: Style.space(72)
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 10
              onHovered: function(on) { if (on) root.setOptionsCursor(10) }
              onModified: function(next) { root.persistSettings({ focusMinutes: next }) }
            }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(shortBreakLabels.implicitHeight, shortBreakField.implicitHeight)

            Column {
              id: shortBreakLabels
              anchors.left: parent.left
              anchors.right: shortBreakField.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)
              Text { width: parent.width; text: qsTr("Short break"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
              Text { width: parent.width; text: qsTr("Seconds for an ordinary eye break"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
            }

            NumberField {
              id: shortBreakField
              width: Style.space(72)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              value: root.settings && root.settings.breakSeconds !== undefined ? Number(root.settings.breakSeconds) : 20
              from: 5
              to: 600
              stepSize: 5
              fieldWidth: Style.space(72)
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 11
              onHovered: function(on) { if (on) root.setOptionsCursor(11) }
              onModified: function(next) { root.persistSettings({ breakSeconds: next }) }
            }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.NumberSettingRow {
            id: longBreakEveryField
            Layout.fillWidth: true
            label: qsTr("Long-break cadence")
            description: qsTr("Make every Nth break long; 0 disables it")
            value: root.settings && root.settings.longBreakEvery !== undefined ? Number(root.settings.longBreakEvery) : 4
            from: 0; to: 20
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 12
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(12) }
            onModified: function(next) { root.persistSettings({ longBreakEvery: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.NumberSettingRow {
            id: longBreakSecondsField
            Layout.fillWidth: true
            label: qsTr("Long break")
            description: qsTr("Seconds for each long break")
            value: root.settings && root.settings.longBreakSeconds !== undefined ? Number(root.settings.longBreakSeconds) : 180
            from: 5; to: 3600; stepSize: 30
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 13
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(13) }
            onModified: function(next) { root.persistSettings({ longBreakSeconds: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.NumberSettingRow {
            id: snoozeBudgetField
            Layout.fillWidth: true
            label: qsTr("Snooze budget")
            description: qsTr("Snoozes allowed during each focus cycle")
            value: root.settings && root.settings.snoozeBudget !== undefined ? Number(root.settings.snoozeBudget) : 3
            from: 0; to: 10
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 14
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(14) }
            onModified: function(next) { root.persistSettings({ snoozeBudget: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.NumberSettingRow {
            id: maximumDelayField
            Layout.fillWidth: true
            label: qsTr("Maximum smart delay")
            description: qsTr("Minutes before a protected break must begin")
            value: root.settings && root.settings.maximumDelayMinutes !== undefined ? Number(root.settings.maximumDelayMinutes) : 15
            from: 0; to: 180; stepSize: 5
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 15
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(15) }
            onModified: function(next) { root.persistSettings({ maximumDelayMinutes: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(enforcementLabels.implicitHeight, enforcementDropdown.implicitHeight)

            Column {
              id: enforcementLabels
              anchors.left: parent.left
              anchors.right: enforcementDropdown.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)
              Text { width: parent.width; text: qsTr("Break enforcement"); color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
              Text { width: parent.width; text: qsTr("Choose when an active break may be skipped"); color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
            }

            Dropdown {
              id: enforcementDropdown
              width: Style.space(132)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              showLabel: false
              value: root.settings && root.settings.enforcement !== undefined ? String(root.settings.enforcement) : "balanced"
              options: [
                { value: "casual", label: qsTr("Casual") },
                { value: "balanced", label: qsTr("Balanced") },
                { value: "hardcore", label: qsTr("Hardcore") }
              ]
              foreground: root.foreground
              accent: root.accent
              fontFamily: root.fontFamily
              hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 16
              onPopupOpenChanged: if (!popupOpen && root.opened && root.page === "options")
                Qt.callLater(function() { optionsFocus.forceActiveFocus() })
              onHovered: function(on) { if (on) root.setOptionsCursor(16) }
              onChanged: function(next) { root.persistSettings({ enforcement: next }) }
            }
          }

          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(10)
            visible: root.settingsTab === "experience"

          LookUi.SectionHeader {
            Layout.fillWidth: true
            Layout.topMargin: Style.space(8)
            label: qsTr("Experience")
            foreground: root.muted
            fontFamily: root.fontFamily
          }

          LookUi.ToggleSettingRow {
            id: reduceMotionRow
            Layout.fillWidth: true
            label: qsTr("Reduce motion")
            description: qsTr("Remove movement and soft-focus reveals")
            checked: root.settings && root.settings.reducedMotion === true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 17
            Accessible.role: Accessible.CheckBox
            Accessible.name: label
            Accessible.checked: checked
            Accessible.onPressAction: clicked()
            onHovered: function(on) { if (on) root.setOptionsCursor(17) }
            KeyNavigation.tab: soundRow
            onClicked: root.persistSettings({ reducedMotion: !checked })
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.ToggleSettingRow {
            id: soundRow
            Layout.fillWidth: true
            label: qsTr("Play break sounds")
            description: qsTr("Use the quiet start and completion cues")
            checked: !root.settings || root.settings.soundEnabled === undefined || root.settings.soundEnabled === true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 18
            Accessible.role: Accessible.CheckBox
            Accessible.name: label
            Accessible.checked: checked
            Accessible.onPressAction: clicked()
            onHovered: function(on) { if (on) root.setOptionsCursor(18) }
            KeyNavigation.tab: soundVolumeField
            KeyNavigation.backtab: reduceMotionRow
            onClicked: root.persistSettings({ soundEnabled: !checked })
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.NumberSettingRow {
            id: soundVolumeField
            Layout.fillWidth: true
            label: qsTr("Sound volume")
            description: qsTr("Volume for LookElsewhere break cues")
            value: root.settings && root.settings.soundVolume !== undefined ? Number(root.settings.soundVolume) : 65
            from: 0; to: 100; stepSize: 5
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 19
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(19) }
            onModified: function(next) { root.persistSettings({ soundVolume: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.ToggleSettingRow {
            id: startSoundRow
            Layout.fillWidth: true
            label: qsTr("Break-start sound")
            description: qsTr("Play a cue when a break begins")
            checked: !root.settings || root.settings.startSoundEnabled === undefined || root.settings.startSoundEnabled === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 20
            onHovered: function(on) { if (on) root.setOptionsCursor(20) }
            onClicked: root.persistSettings({ startSoundEnabled: !checked })
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.ToggleSettingRow {
            id: completionSoundRow
            Layout.fillWidth: true
            label: qsTr("Break-completion sound")
            description: qsTr("Play a cue when a break finishes")
            checked: !root.settings || root.settings.completionSoundEnabled === undefined || root.settings.completionSoundEnabled === true
            foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 21
            onHovered: function(on) { if (on) root.setOptionsCursor(21) }
            onClicked: root.persistSettings({ completionSoundEnabled: !checked })
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.DropdownSettingRow {
            id: outputModeDropdown
            Layout.fillWidth: true
            label: qsTr("Break outputs")
            description: qsTr("Choose where full-screen breaks appear")
            value: root.settings && root.settings.outputMode !== undefined ? String(root.settings.outputMode) : "all"
            options: [{ value: "all", label: qsTr("All displays") }, { value: "focused", label: qsTr("Focused display") }]
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 22
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(22) }
            onPopupClosed: if (root.opened && root.page === "options") Qt.callLater(function() { optionsFocus.forceActiveFocus() })
            onChanged: function(next) { root.persistSettings({ outputMode: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.DropdownSettingRow {
            id: displayModeDropdown
            Layout.fillWidth: true
            label: qsTr("Bar display")
            description: qsTr("Choose what LookElsewhere shows in the bar")
            value: root.settings && root.settings.displayMode !== undefined ? String(root.settings.displayMode) : "icon-and-time"
            options: [
              { value: "icon-and-time", label: qsTr("Icon and time") },
              { value: "icon", label: qsTr("Icon only") },
              { value: "time", label: qsTr("Time only") }
            ]
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 23
            foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
            onHovered: function(on) { if (on) root.setOptionsCursor(23) }
            onPopupClosed: if (root.opened && root.page === "options") Qt.callLater(function() { optionsFocus.forceActiveFocus() })
            onChanged: function(next) { root.persistSettings({ displayMode: next }) }
          }

          PanelSeparator { Layout.fillWidth: true; foreground: root.foreground }

          LookUi.ToggleSettingRow {
            id: keyboardHintRow
            Layout.fillWidth: true
            label: qsTr("Show keyboard hints")
            description: qsTr("Show action keys whenever the panel opens")
            checked: root.settings && root.settings.showKeyboardHints === true
            foreground: root.foreground
            accent: root.accent
            fontFamily: root.fontFamily
            hasCursor: root.optionsCursorActive && root.optionsCursorIndex === 24
            Accessible.role: Accessible.CheckBox
            Accessible.name: label
            Accessible.checked: checked
            Accessible.onPressAction: clicked()
            onHovered: function(on) { if (on) root.setOptionsCursor(24) }
            KeyNavigation.tab: shortcutsButton
            KeyNavigation.backtab: soundRow
            onClicked: root.persistSettings({ showKeyboardHints: !checked })
          }

          }

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
          Layout.topMargin: -Style.space(3)
          visible: root.page === "now"

          RowLayout {
            id: actionRow
            readonly property real fitScale: Math.min(1,
              (parent.width - Style.space(4)) / Math.max(1, implicitWidth))
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
            KeyNavigation.tab: root.delayActionsEnabled ? postpone1Button : shortcutsButton
            KeyNavigation.backtab: settingsButton
            KeyNavigation.up: shortcutsButton
            KeyNavigation.right: root.delayActionsEnabled ? postpone1Button : settingsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: label
            Accessible.onPressAction: clicked()
            onClicked: root.takeBreakAndClose()

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
            KeyNavigation.up: statsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: root.delayActionsEnabled
              ? qsTr("Snooze next break for 1 minute")
              : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
            Accessible.onPressAction: clicked()
            onClicked: root.postponeAndClose(1)

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
            KeyNavigation.up: statsButton
            Keys.onEscapePressed: root.dismissHintsOrClose()
            Accessible.role: Accessible.Button
            Accessible.name: root.delayActionsEnabled
              ? qsTr("Snooze next break for 5 minutes")
              : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
            Accessible.onPressAction: clicked()
            onClicked: root.postponeAndClose(5)

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
              KeyNavigation.tab: shortcutsButton
              KeyNavigation.backtab: postpone5Button
              KeyNavigation.left: postpone5Button
              KeyNavigation.right: settingsButton
              KeyNavigation.up: settingsButton
              Keys.onEscapePressed: root.dismissHintsOrClose()
              Accessible.role: Accessible.Button
              Accessible.name: root.delayActionsEnabled
                ? qsTr("Snooze next break for 15 minutes")
                : qsTr("Snooze unavailable; %1").arg(root.snoozeUnavailableSummary)
              Accessible.onPressAction: clicked()
              onClicked: root.postponeAndClose(15)

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
  }

  Process {
    id: settingsEditor
    command: ["omarchy", "launch", "config", "editor", Quickshell.env("HOME") + "/.config/omarchy/shell.json"]
  }

}

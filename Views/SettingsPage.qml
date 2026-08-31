import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "../Model.js" as Model
import "../Ui" as ProductUi
import "../vendor/qmlpack/oma-command-layer/Ui" as OmaCommands
import "../vendor/qmlpack/oma-command-layer/Ui/CommandModel.js" as CommandModel
import "../vendor/qmlpack/oma-ui-kit/Ui" as LookUi

ColumnLayout {
  id: settingsPage

  property var service: null
  property var settings: ({})
  property var shortcuts: ({})
  property bool keyboardHintsVisible: false
  property var commandLayer: null
  property bool manuallyPaused: false
  property bool active: false
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property Item focusProxy: null
  property Item settingsButtonTarget: null
  property Item shortcutsButtonTarget: null
  property var scrollFlickable: null
  property real topInset: 0
  property string settingsTab: "general"
  property int cursorIndex: 0
  property bool cursorActive: false

  readonly property bool editorActive: focusMinutesField.editorActive
    || shortBreakField.editorActive
    || longBreakEveryField.editorActive
    || longBreakSecondsField.editorActive
    || snoozeBudgetField.editorActive
    || maximumDelayField.editorActive
    || shortBreakTitleField.editorActive || shortBreakSubtitleField.editorActive
    || longBreakTitleField.editorActive || longBreakSubtitleField.editorActive
    || soundVolumeField.editorActive || plannedBreaksPage.editorActive
  readonly property bool dropdownOpen: enforcementDropdown.popupOpen
    || officeStartDropdown.popupOpen || officeEndDropdown.popupOpen
    || outputModeDropdown.popupOpen || displayModeDropdown.popupOpen
    || panelPatternDropdown.popupOpen || plannedBreaksPage.dropdownOpen
  readonly property string activeAppId: service ? String(service.activeAppId || "").trim() : ""
  readonly property bool activeAppProtected: service
    && Model.matchesProtectedApp(activeAppId, service.config.protectedApps)
  readonly property Item initialFocusTarget: settingsTabs
  readonly property Item finalFocusTarget: {
    var controls = targets()
    return controls.length ? controls[controls.length - 1] : settingsTabs
  }
  readonly property string cursorAccessibleName: {
    var controls = targets()
    if (!cursorActive || cursorIndex < 0 || cursorIndex >= controls.length)
      return qsTr("Settings navigation")
    var target = controls[cursorIndex]
    return target && target.label !== undefined
      ? qsTr("Settings: %1").arg(String(target.label))
      : qsTr("Settings navigation")
  }

  signal persistRequested(var values)
  signal pauseRequested()
  signal editRequested()
  signal closeRequested()

  Layout.fillWidth: true
  Layout.topMargin: Style.space(8)
  spacing: Style.space(10)

  function focusInitial() { settingsTabs.forceActiveFocus() }
  function selectTab(name) {
    var aliases = { appearance: "general", experience: "general", plans: "schedule" }
    var next = aliases[name] || name
    settingsTab = ["general", "breaks", "schedule", "context"].indexOf(next) >= 0
      ? next : "general"
    cursorActive = false
    cursorIndex = 0
    if (scrollFlickable) scrollFlickable.contentY = 0
  }
  function reset() {
    selectTab("general")
  }
  function persistSettings(values) { persistRequested(values) }
  function toggleManualPause() { pauseRequested() }
  function dismissHintsOrClose() { closeRequested() }
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
  function targets() {
    var byTab = {
      general: [panelPatternDropdown, soundRow, soundVolumeField,
        startSoundRow, completionSoundRow, outputModeDropdown, displayModeDropdown,
        reduceMotionRow, reduceTransparencyRow, keyboardHintRow, editSettingsButton],
      context: [idleDetectionRow, recentInputDetectionRow, fullscreenDetectionRow, mediaDetectionRow,
        steamPauseRow, microphoneDetectionRow, screenSharingDetectionRow, dictationDetectionRow, protectedAppsRow],
      breaks: [pauseBreaksButton, focusMinutesField, shortBreakField, longBreakEveryField,
        longBreakSecondsField, snoozeBudgetField, maximumDelayField,
        enforcementDropdown, shortBreakTitleField, shortBreakSubtitleField,
        longBreakTitleField, longBreakSubtitleField],
      schedule: [plannedBreaksPage.routineTarget, plannedBreaksPage.enabledTarget,
        plannedBreaksPage.nameTarget, plannedBreaksPage.startTarget,
        plannedBreaksPage.durationTarget, plannedBreaksPage.daysTarget,
        plannedBreaksPage.removeTarget, plannedBreaksPage.addTarget,
        officeHoursRow, officeStartDropdown, officeEndDropdown].filter(function(item) {
          return item && item.visible
        })
    }
    return byTab[settingsTab] || []
  }
  function setCursor(index) {
    var controls = targets()
    if (!controls.length) return
    cursorIndex = Math.max(0, Math.min(controls.length - 1, index))
    cursorActive = true
    ensureCursorVisible(controls[cursorIndex])
  }
  function hasCursorFor(target) {
    return cursorActive && targets()[cursorIndex] === target
  }
  function setCursorTarget(target) {
    var index = targets().indexOf(target)
    if (index >= 0) setCursor(index)
  }
  function moveCursor(delta) {
    if (cursorActive && delta < 0 && cursorIndex === 0) {
      cursorActive = false
      settingsTabs.forceActiveFocus()
      ensureCursorVisible(settingsTabs)
      return
    }
    if (focusProxy) focusProxy.forceActiveFocus()
    setCursor(cursorActive ? cursorIndex + delta : 0)
  }
  function activateCursor() {
    if (!cursorActive) { setCursor(0); return }
    var target = targets()[cursorIndex]
    if (target && typeof target.activate === "function") target.activate()
  }
  function moveHorizontal(delta) {
    var target = targets()[cursorIndex]
    if (settingsTab === "schedule" && target === plannedBreaksPage.daysTarget)
      plannedBreaksPage.moveDays(delta)
  }
  function toggleCurrentProtectedApp() {
    if (!service || !activeAppId) return
    persistSettings({ protectedApps: Model.toggleProtectedApp(service.config.protectedApps, activeAppId) })
  }
  function ensureCursorVisible(item) {
    var flick = scrollFlickable
    if (!item || !flick || flick.contentY === undefined) return
    var point = item.mapToItem(flick.contentItem || flick, 0, 0)
    var margin = Style.space(6)
    if (point.y < flick.contentY + margin)
      flick.contentY = Math.max(0, point.y - margin)
    else if (point.y + item.height > flick.contentY + flick.height - margin)
      flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height),
        point.y + item.height + margin - flick.height)
  }
  ProductUi.SettingsCategoryBar {
    id: settingsTabs
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: settingsPage.topInset + Style.space(8)
    options: [
      { value: "general", label: qsTr("General"), key: CommandModel.label(settingsPage.shortcuts.generalTab), iconPath: "M40,88H73a32,32,0,0,0,62,0h81a8,8,0,0,0,0-16H135a32,32,0,0,0-62,0H40a8,8,0,0,0,0,16Zm64-24A16,16,0,1,1,88,80,16,16,0,0,1,104,64ZM216,168H199a32,32,0,0,0-62,0H40a8,8,0,0,0,0,16h97a32,32,0,0,0,62,0h17a8,8,0,0,0,0-16Zm-48,24a16,16,0,1,1,16-16A16,16,0,0,1,168,192Z" },
      { value: "breaks", label: qsTr("Breaks"), key: CommandModel.label(settingsPage.shortcuts.breaksTab), iconPath: "M128,40a96,96,0,1,0,96,96A96.11,96.11,0,0,0,128,40Zm0,176a80,80,0,1,1,80-80A80.09,80.09,0,0,1,128,216ZM173.66,90.34a8,8,0,0,1,0,11.32l-40,40a8,8,0,0,1-11.32-11.32l40-40A8,8,0,0,1,173.66,90.34ZM96,16a8,8,0,0,1,8-8h48a8,8,0,0,1,0,16H104A8,8,0,0,1,96,16Z" },
      { value: "schedule", label: qsTr("Schedule"), key: CommandModel.label(settingsPage.shortcuts.plansTab), iconPath: "M208,32H184V24a8,8,0,0,0-16,0v8H88V24a8,8,0,0,0-16,0v8H48A16,16,0,0,0,32,48V208a16,16,0,0,0,16,16H208a16,16,0,0,0,16-16V48A16,16,0,0,0,208,32ZM72,48v8a8,8,0,0,0,16,0V48h80v8a8,8,0,0,0,16,0V48h24V80H48V48ZM208,208H48V96H208V208Zm-68-76a12,12,0,1,1-12-12A12,12,0,0,1,140,132Zm44,0a12,12,0,1,1-12-12A12,12,0,0,1,184,132ZM96,172a12,12,0,1,1-12-12A12,12,0,0,1,96,172Zm44,0a12,12,0,1,1-12-12A12,12,0,0,1,140,172Zm44,0a12,12,0,1,1-12-12A12,12,0,0,1,184,172Z" },
      { value: "context", label: qsTr("Context"), key: CommandModel.label(settingsPage.shortcuts.contextTab), iconPath: "M208,40H48A16,16,0,0,0,32,56v56c0,52.72,25.52,84.67,46.93,102.19,23.06,18.86,46,25.26,47,25.53a8,8,0,0,0,4.2,0c1-.27,23.91-6.67,47-25.53C198.48,196.67,224,164.72,224,112V56A16,16,0,0,0,208,40Zm0,72c0,37.07-13.66,67.16-40.6,89.42A129.3,129.3,0,0,1,128,223.62a128.25,128.25,0,0,1-38.92-21.81C61.82,179.51,48,149.3,48,112l0-56,160,0ZM82.34,141.66a8,8,0,0,1,11.32-11.32L112,148.69l50.34-50.35a8,8,0,0,1,11.32,11.32l-56,56a8,8,0,0,1-11.32,0Z" }
    ]
    value: settingsPage.settingsTab
    hintsVisible: settingsPage.keyboardHintsVisible
    foreground: settingsPage.foreground
    background: Color.popups.background
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    KeyNavigation.tab: settingsPage.settingsTab === "general" ? panelPatternDropdown
      : settingsPage.settingsTab === "breaks" ? pauseBreaksButton
      : settingsPage.settingsTab === "schedule" ? plannedBreaksPage
      : idleDetectionRow
    Keys.onEscapePressed: settingsPage.dismissHintsOrClose()
    Keys.onTabPressed: {
      settingsPage.focusProxy.forceActiveFocus()
      settingsPage.setCursor(0)
    }
    Keys.onBacktabPressed: settingsPage.settingsButtonTarget.forceActiveFocus()
    onDownRequested: {
      settingsPage.focusProxy.forceActiveFocus()
      settingsPage.setCursor(0)
    }
    onUpRequested: settingsPage.settingsButtonTarget.forceActiveFocus()
    onChanged: function(next) {
      settingsPage.selectTab(next)
    }
  }

  PlannedBreaksPage {
    id: plannedBreaksPage
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    visible: settingsPage.settingsTab === "schedule"
    settings: settingsPage.settings
    foreground: settingsPage.foreground
    muted: settingsPage.muted
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    cursorTarget: settingsPage.cursorActive ? settingsPage.targets()[settingsPage.cursorIndex] : null
    onPersistRequested: function(values) { settingsPage.persistSettings(values) }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "breaks"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    label: qsTr("Reminders")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.ToggleSettingRow {
    id: pauseBreaksButton
    Layout.fillWidth: true
    label: qsTr("Break reminders")
    description: qsTr("Show scheduled break reminders")
    checked: !!settingsPage.service && !settingsPage.manuallyPaused
    enabled: !!settingsPage.service && Model.canTogglePause(settingsPage.service.phase)
    foreground: settingsPage.foreground
    muted: settingsPage.muted
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(pauseBreaksButton)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(pauseBreaksButton) }
    KeyNavigation.tab: focusMinutesField
    Keys.onEscapePressed: settingsPage.dismissHintsOrClose()
    onClicked: settingsPage.toggleManualPause()

    OmaCommands.CommandHint {
      commandLayer: settingsPage.commandLayer
      keyText: CommandModel.label(settingsPage.shortcuts.pause)
      available: pauseBreaksButton.enabled
      customPosition: true
      badgeX: parent.controlX - badgeWidth - Style.space(4)
      badgeY: parent.controlY + (parent.controlHeight - badgeHeight) / 2
    }
  }

  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "schedule"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Office hours")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.ToggleSettingRow {
    id: officeHoursRow
    Layout.fillWidth: true
    label: qsTr("Use office hours")
    description: qsTr("Show break reminders only during these hours")
    checked: settingsPage.settings && settingsPage.settings.officeHoursEnabled === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(officeHoursRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(officeHoursRow) }
    onClicked: settingsPage.persistSettings({ officeHoursEnabled: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.DropdownSettingRow {
    id: officeStartDropdown
    Layout.fillWidth: true
    label: qsTr("Starts")
    description: qsTr("Beginning of the active schedule")
    value: settingsPage.settings && settingsPage.settings.officeStart !== undefined ? String(settingsPage.settings.officeStart) : "08:00"
    options: settingsPage.clockOptions()
    hasCursor: settingsPage.hasCursorFor(officeStartDropdown)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(officeStartDropdown) }
    onChanged: function(next) { settingsPage.persistSettings({ officeStart: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.DropdownSettingRow {
    id: officeEndDropdown
    Layout.fillWidth: true
    label: qsTr("Ends")
    description: qsTr("End of the active schedule; overnight is supported")
    value: settingsPage.settings && settingsPage.settings.officeEnd !== undefined ? String(settingsPage.settings.officeEnd) : "18:00"
    options: settingsPage.clockOptions()
    hasCursor: settingsPage.hasCursorFor(officeEndDropdown)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(officeEndDropdown) }
    onChanged: function(next) { settingsPage.persistSettings({ officeEnd: next }) }
  }

  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "context"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Smart context")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.ToggleSettingRow {
    id: idleDetectionRow
    Layout.fillWidth: true
    label: qsTr("Pause while idle")
    description: qsTr("Count active screen time instead of time away")
    checked: !settingsPage.settings || settingsPage.settings.idleDetection === undefined || settingsPage.settings.idleDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(idleDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(idleDetectionRow) }
    onClicked: settingsPage.persistSettings({ idleDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: steamPauseRow
    Layout.fillWidth: true
    label: qsTr("Pause during games")
    description: settingsPage.service && settingsPage.service.sundownIntegrationStatus === "Connected"
      ? (settingsPage.service.steamPauseActive
          ? qsTr("Paused now; Sundown detected an active game")
          : qsTr("Sundown is connected and watching for games"))
      : settingsPage.service && settingsPage.service.sundownIntegrationStatus === "Unavailable"
        ? qsTr("Sundown stopped responding; window-based protection remains")
        : qsTr("Install Sundown for reliable Steam, Proton, and Heroic detection")
    checked: !settingsPage.settings || settingsPage.settings.pauseDuringSteamGames === undefined
      || settingsPage.settings.pauseDuringSteamGames === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(steamPauseRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(steamPauseRow) }
    onClicked: settingsPage.persistSettings({ pauseDuringSteamGames: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: recentInputDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect recent activity")
    description: qsTr("Hold the final ten seconds while input continues")
    checked: !settingsPage.settings || settingsPage.settings.recentInputDetection === undefined || settingsPage.settings.recentInputDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(recentInputDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(recentInputDetectionRow) }
    onClicked: settingsPage.persistSettings({ recentInputDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: fullscreenDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect fullscreen work")
    description: qsTr("Delay a due break while fullscreen")
    checked: !settingsPage.settings || settingsPage.settings.fullscreenDetection === undefined || settingsPage.settings.fullscreenDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(fullscreenDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(fullscreenDetectionRow) }
    onClicked: settingsPage.persistSettings({ fullscreenDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: mediaDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect focused video")
    description: qsTr("Delay while the focused app is playing media")
    checked: !settingsPage.settings || settingsPage.settings.mediaDetection === undefined || settingsPage.settings.mediaDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(mediaDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(mediaDetectionRow) }
    onClicked: settingsPage.persistSettings({ mediaDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(browserStatusLabels.implicitHeight, browserStatus.implicitHeight)
    Accessible.role: Accessible.StaticText
    Accessible.name: browserStatusLabels.label + ", " + browserStatus.text + ". "
      + browserStatusLabels.description

    LookUi.SettingLabels {
      id: browserStatusLabels
      anchors.left: parent.left
      anchors.right: browserStatus.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      label: qsTr("Browser detection")
      description: settingsPage.service && settingsPage.service.browserIntegrationStatus === "Enhanced"
        ? qsTr("Foreground video and Picture-in-Picture are detected directly")
        : settingsPage.service && settingsPage.service.browserIntegrationStatus === "Unavailable"
          ? qsTr("Extension disconnected; system detection remains active")
          : qsTr("Using system media signals; the extension is optional")
      foreground: settingsPage.foreground
      muted: settingsPage.muted
      fontFamily: settingsPage.fontFamily
    }

    Text {
      id: browserStatus
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: settingsPage.service ? settingsPage.service.browserIntegrationStatus : qsTr("Standard")
      color: text === "Enhanced" ? settingsPage.accent : settingsPage.muted
      font.family: settingsPage.fontFamily
      font.pixelSize: Style.font.body
      font.weight: Font.DemiBold
      textFormat: Text.PlainText
      Accessible.ignored: true
    }
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: microphoneDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect microphone use")
    description: qsTr("Delay during calls without recording audio")
    checked: !settingsPage.settings || settingsPage.settings.microphoneDetection === undefined || settingsPage.settings.microphoneDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(microphoneDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(microphoneDetectionRow) }
    onClicked: settingsPage.persistSettings({ microphoneDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: screenSharingDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect screen sharing")
    description: qsTr("Delay when PipeWire identifies sharing or recording")
    checked: !settingsPage.settings || settingsPage.settings.screenSharingDetection === undefined || settingsPage.settings.screenSharingDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(screenSharingDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(screenSharingDetectionRow) }
    onClicked: settingsPage.persistSettings({ screenSharingDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: dictationDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect dictation")
    description: qsTr("Delay while Omarchy dictation is active")
    checked: !settingsPage.settings || settingsPage.settings.dictationDetection === undefined || settingsPage.settings.dictationDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(dictationDetectionRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(dictationDetectionRow) }
    onClicked: settingsPage.persistSettings({ dictationDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  Item {
    id: protectedAppsRow
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(protectedAppsLabels.implicitHeight, currentAppButton.implicitHeight)

    function activate() { settingsPage.toggleCurrentProtectedApp() }

    HoverHandler {
      onHoveredChanged: if (hovered) settingsPage.setCursorTarget(protectedAppsRow)
    }

    LookUi.SettingLabels {
      id: protectedAppsLabels
      anchors.left: parent.left
      anchors.right: currentAppButton.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      label: qsTr("Protected applications")
      description: settingsPage.service && settingsPage.service.config.protectedApps.length
        ? settingsPage.service.config.protectedApps.join(", ") : qsTr("None configured")
      foreground: settingsPage.foreground
      muted: settingsPage.muted
      fontFamily: settingsPage.fontFamily
    }

    LookUi.WeightedButton {
      id: currentAppButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      label: settingsPage.activeAppProtected ? qsTr("Remove current app") : qsTr("Add current app")
      actionEnabled: settingsPage.activeAppId !== ""
      disabledTooltipText: qsTr("No focused application was detected")
      foreground: settingsPage.foreground
      accent: settingsPage.accent
      fontFamily: settingsPage.fontFamily
      hasCursor: settingsPage.hasCursorFor(protectedAppsRow)
      onHovered: if (hovered) settingsPage.setCursorTarget(protectedAppsRow)
      onClicked: settingsPage.toggleCurrentProtectedApp()
    }

    MouseArea {
      anchors.left: parent.left
      anchors.right: currentAppButton.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.rightMargin: Style.space(12)
      cursorShape: settingsPage.activeAppId ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: protectedAppsRow.activate()
    }
  }

  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "breaks"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Break schedule")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.NumberSettingRow {
    id: focusMinutesField
    Layout.fillWidth: true
    label: qsTr("Focus interval")
    description: qsTr("Minutes of active screen time between breaks")
    value: settingsPage.settings && settingsPage.settings.focusMinutes !== undefined ? Number(settingsPage.settings.focusMinutes) : 20
    from: 1; to: 180
    hasCursor: settingsPage.hasCursorFor(focusMinutesField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(focusMinutesField) }
    onModified: function(next) { settingsPage.persistSettings({ focusMinutes: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: shortBreakField
    Layout.fillWidth: true
    label: qsTr("Short break")
    description: qsTr("Seconds for an ordinary eye break")
    value: settingsPage.settings && settingsPage.settings.breakSeconds !== undefined ? Number(settingsPage.settings.breakSeconds) : 20
    from: 5; to: 600; stepSize: 5
    hasCursor: settingsPage.hasCursorFor(shortBreakField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(shortBreakField) }
    onModified: function(next) { settingsPage.persistSettings({ breakSeconds: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: longBreakEveryField
    Layout.fillWidth: true
    label: qsTr("Long-break cadence")
    description: qsTr("Make every Nth break long; 0 disables it")
    value: settingsPage.settings && settingsPage.settings.longBreakEvery !== undefined ? Number(settingsPage.settings.longBreakEvery) : 4
    from: 0; to: 20
    hasCursor: settingsPage.hasCursorFor(longBreakEveryField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(longBreakEveryField) }
    onModified: function(next) { settingsPage.persistSettings({ longBreakEvery: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: longBreakSecondsField
    Layout.fillWidth: true
    label: qsTr("Long break")
    description: qsTr("Seconds for each long break")
    value: settingsPage.settings && settingsPage.settings.longBreakSeconds !== undefined ? Number(settingsPage.settings.longBreakSeconds) : 180
    from: 5; to: 3600; stepSize: 30
    hasCursor: settingsPage.hasCursorFor(longBreakSecondsField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(longBreakSecondsField) }
    onModified: function(next) { settingsPage.persistSettings({ longBreakSeconds: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: snoozeBudgetField
    Layout.fillWidth: true
    label: qsTr("Snooze budget")
    description: qsTr("Snoozes allowed during each focus cycle")
    value: settingsPage.settings && settingsPage.settings.snoozeBudget !== undefined ? Number(settingsPage.settings.snoozeBudget) : 3
    from: 0; to: 10
    hasCursor: settingsPage.hasCursorFor(snoozeBudgetField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(snoozeBudgetField) }
    onModified: function(next) { settingsPage.persistSettings({ snoozeBudget: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: maximumDelayField
    Layout.fillWidth: true
    label: qsTr("Maximum smart delay")
    description: qsTr("Minutes before a protected break must begin")
    value: settingsPage.settings && settingsPage.settings.maximumDelayMinutes !== undefined ? Number(settingsPage.settings.maximumDelayMinutes) : 15
    from: 0; to: 180; stepSize: 5
    hasCursor: settingsPage.hasCursorFor(maximumDelayField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(maximumDelayField) }
    onModified: function(next) { settingsPage.persistSettings({ maximumDelayMinutes: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.DropdownSettingRow {
    id: enforcementDropdown
    Layout.fillWidth: true
    label: qsTr("Break enforcement")
    description: qsTr("Choose when an active break may be skipped")
    value: settingsPage.settings && settingsPage.settings.enforcement !== undefined ? String(settingsPage.settings.enforcement) : "balanced"
    options: [
      { value: "casual", label: qsTr("Casual") },
      { value: "balanced", label: qsTr("Balanced") },
      { value: "hardcore", label: qsTr("Hardcore") }
    ]
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(enforcementDropdown)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(enforcementDropdown) }
    onChanged: function(next) { settingsPage.persistSettings({ enforcement: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Break screen")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  ProductUi.TextSettingRow {
    id: shortBreakTitleField
    Layout.fillWidth: true
    label: qsTr("Short-break title")
    description: qsTr("Heading for ordinary eye breaks")
    value: settingsPage.settings && settingsPage.settings.breakTitle !== undefined
      ? String(settingsPage.settings.breakTitle) : "Look elsewhere"
    hasCursor: settingsPage.hasCursorFor(shortBreakTitleField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(shortBreakTitleField) }
    onModified: function(next) { settingsPage.persistSettings({ breakTitle: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  ProductUi.TextSettingRow {
    id: shortBreakSubtitleField
    Layout.fillWidth: true
    label: qsTr("Short-break guidance")
    description: qsTr("Message beneath the short-break title")
    value: settingsPage.settings && settingsPage.settings.breakSubtitle !== undefined
      ? String(settingsPage.settings.breakSubtitle)
      : "Let your eyes settle on something distant. Breathe. The screen will still be here."
    hasCursor: settingsPage.hasCursorFor(shortBreakSubtitleField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(shortBreakSubtitleField) }
    onModified: function(next) { settingsPage.persistSettings({ breakSubtitle: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  ProductUi.TextSettingRow {
    id: longBreakTitleField
    Layout.fillWidth: true
    label: qsTr("Long-break title")
    description: qsTr("Heading for longer recovery breaks")
    value: settingsPage.settings && settingsPage.settings.longBreakTitle !== undefined
      ? String(settingsPage.settings.longBreakTitle) : "Look elsewhere"
    hasCursor: settingsPage.hasCursorFor(longBreakTitleField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(longBreakTitleField) }
    onModified: function(next) { settingsPage.persistSettings({ longBreakTitle: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  ProductUi.TextSettingRow {
    id: longBreakSubtitleField
    Layout.fillWidth: true
    label: qsTr("Long-break guidance")
    description: qsTr("Message beneath the long-break title")
    value: settingsPage.settings && settingsPage.settings.longBreakSubtitle !== undefined
      ? String(settingsPage.settings.longBreakSubtitle)
      : "Stand up, stretch, and leave the screen for a few minutes."
    hasCursor: settingsPage.hasCursorFor(longBreakSubtitleField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(longBreakSubtitleField) }
    onModified: function(next) { settingsPage.persistSettings({ longBreakSubtitle: next }) }
  }

  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "general"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Interface")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.DropdownSettingRow {
    id: panelPatternDropdown
    Layout.fillWidth: true
    label: qsTr("Panel background")
    description: qsTr("Add a subtle pattern behind the plugin panel")
    value: settingsPage.settings && settingsPage.settings.panelPattern !== undefined
      ? String(settingsPage.settings.panelPattern) : "off"
    options: [
      { value: "off", label: qsTr("Off") },
      { value: "topography", label: qsTr("Topography") },
      { value: "graph-paper", label: qsTr("Graph paper") },
      { value: "wiggle", label: qsTr("Wiggle") },
      { value: "bank-note", label: qsTr("Bank note") },
      { value: "diagonal-lines", label: qsTr("Diagonal lines") }
    ]
    hasCursor: settingsPage.hasCursorFor(panelPatternDropdown)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(panelPatternDropdown) }
    onChanged: function(next) { settingsPage.persistSettings({ panelPattern: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Sounds")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.ToggleSettingRow {
    id: soundRow
    Layout.fillWidth: true
    label: qsTr("Play break sounds")
    description: qsTr("Use the quiet start and completion cues")
    checked: !settingsPage.settings || settingsPage.settings.soundEnabled === undefined || settingsPage.settings.soundEnabled === true
    foreground: settingsPage.foreground
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(soundRow)
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: clicked()
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(soundRow) }
    KeyNavigation.tab: soundVolumeField
    KeyNavigation.backtab: panelPatternDropdown
    onClicked: settingsPage.persistSettings({ soundEnabled: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: soundVolumeField
    Layout.fillWidth: true
    label: qsTr("Sound volume")
    description: qsTr("Volume for LookElsewhere break cues")
    value: settingsPage.settings && settingsPage.settings.soundVolume !== undefined ? Number(settingsPage.settings.soundVolume) : 65
    from: 0; to: 100; stepSize: 5
    hasCursor: settingsPage.hasCursorFor(soundVolumeField)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(soundVolumeField) }
    onModified: function(next) { settingsPage.persistSettings({ soundVolume: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.ToggleSettingRow {
    id: startSoundRow
    Layout.fillWidth: true
    label: qsTr("Break-start sound")
    description: qsTr("Play a cue when a break begins")
    checked: !settingsPage.settings || settingsPage.settings.startSoundEnabled === undefined || settingsPage.settings.startSoundEnabled === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(startSoundRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(startSoundRow) }
    onClicked: settingsPage.persistSettings({ startSoundEnabled: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.ToggleSettingRow {
    id: completionSoundRow
    Layout.fillWidth: true
    label: qsTr("Break-completion sound")
    description: qsTr("Play a cue when a break finishes")
    checked: !settingsPage.settings || settingsPage.settings.completionSoundEnabled === undefined || settingsPage.settings.completionSoundEnabled === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(completionSoundRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(completionSoundRow) }
    onClicked: settingsPage.persistSettings({ completionSoundEnabled: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Displays")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.DropdownSettingRow {
    id: outputModeDropdown
    Layout.fillWidth: true
    label: qsTr("Break outputs")
    description: qsTr("Choose where full-screen breaks appear")
    value: settingsPage.settings && settingsPage.settings.outputMode !== undefined ? String(settingsPage.settings.outputMode) : "all"
    options: [{ value: "all", label: qsTr("All displays") }, { value: "focused", label: qsTr("Focused display") }]
    hasCursor: settingsPage.hasCursorFor(outputModeDropdown)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(outputModeDropdown) }
    onChanged: function(next) { settingsPage.persistSettings({ outputMode: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.DropdownSettingRow {
    id: displayModeDropdown
    Layout.fillWidth: true
    label: qsTr("Bar display")
    description: qsTr("Choose what LookElsewhere shows in the bar")
    value: settingsPage.settings && settingsPage.settings.displayMode !== undefined ? String(settingsPage.settings.displayMode) : "icon-and-time"
    options: [
      { value: "icon-and-time", label: qsTr("Icon and time") },
      { value: "icon", label: qsTr("Icon only") },
      { value: "time", label: qsTr("Time only") }
    ]
    hasCursor: settingsPage.hasCursorFor(displayModeDropdown)
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(displayModeDropdown) }
    onChanged: function(next) { settingsPage.persistSettings({ displayMode: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Accessibility")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.ToggleSettingRow {
    id: reduceMotionRow
    Layout.fillWidth: true
    label: qsTr("Reduce motion")
    description: qsTr("Remove movement and soft-focus reveals")
    checked: settingsPage.settings && settingsPage.settings.reducedMotion === true
    foreground: settingsPage.foreground
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(reduceMotionRow)
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: clicked()
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(reduceMotionRow) }
    onClicked: settingsPage.persistSettings({ reducedMotion: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.ToggleSettingRow {
    id: reduceTransparencyRow
    Layout.fillWidth: true
    label: qsTr("Reduce transparency")
    description: qsTr("Remove decorative patterns and soft-focus effects")
    checked: settingsPage.settings && settingsPage.settings.reducedTransparency === true
    foreground: settingsPage.foreground
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(reduceTransparencyRow)
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(reduceTransparencyRow) }
    onClicked: settingsPage.persistSettings({ reducedTransparency: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.ToggleSettingRow {
    id: keyboardHintRow
    Layout.fillWidth: true
    label: qsTr("Show keyboard hints")
    description: qsTr("Show action keys whenever the panel opens")
    checked: settingsPage.settings && settingsPage.settings.showKeyboardHints === true
    foreground: settingsPage.foreground
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.hasCursorFor(keyboardHintRow)
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: clicked()
    onHovered: function(on) { if (on) settingsPage.setCursorTarget(keyboardHintRow) }
    KeyNavigation.tab: settingsPage.shortcutsButtonTarget
    KeyNavigation.backtab: reduceTransparencyRow
    onClicked: settingsPage.persistSettings({ showKeyboardHints: !checked })
  }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Configuration")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(editSettingsLabels.implicitHeight, editSettingsButton.implicitHeight)

    function activate() { settingsPage.editRequested() }

    HoverHandler {
      onHoveredChanged: if (hovered) settingsPage.setCursorTarget(editSettingsButton)
    }

    Column {
      id: editSettingsLabels
      anchors.left: parent.left
      anchors.right: editSettingsButton.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)
      Text { width: parent.width; text: qsTr("Omarchy configuration"); color: settingsPage.foreground; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
      Text { width: parent.width; text: qsTr("Open the Omarchy Shell configuration file"); color: settingsPage.muted; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
    }

    LookUi.WeightedButton {
      id: editSettingsButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      label: qsTr("Open file")
      labelWeight: Font.DemiBold
      bordered: true
      focusable: true
      foreground: settingsPage.foreground
      accent: settingsPage.accent
      fontFamily: settingsPage.fontFamily
      hasCursor: settingsPage.hasCursorFor(editSettingsButton)
      onHovered: function(on) { if (on) settingsPage.setCursorTarget(editSettingsButton) }
      Keys.onEscapePressed: settingsPage.dismissHintsOrClose()
      Accessible.role: Accessible.Button
      Accessible.name: qsTr("Open Omarchy Shell configuration file")
      Accessible.onPressAction: clicked()
      onClicked: settingsPage.editRequested()
    }

    MouseArea {
      anchors.left: parent.left
      anchors.right: editSettingsButton.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.rightMargin: Style.space(12)
      cursorShape: Qt.PointingHandCursor
      onClicked: parent.activate()
    }

    OmaCommands.CommandHint {
      commandLayer: settingsPage.commandLayer
      keyText: CommandModel.label(settingsPage.shortcuts.edit)
      customPosition: true
      badgeX: parent.width - badgeWidth
      badgeY: editSettingsButton.y - badgeHeight / 2
    }
  }

  }
}

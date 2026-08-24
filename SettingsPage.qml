import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model
import "Ui" as LookUi

ColumnLayout {
  id: settingsPage

  property var service: null
  property var settings: ({})
  property var shortcuts: ({})
  property bool keyboardHintsVisible: false
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

  readonly property bool editorActive: focusMinutesField.field.activeFocus
    || focusMinutesField.field.contentItem.activeFocus
    || shortBreakField.field.activeFocus
    || shortBreakField.field.contentItem.activeFocus
    || longBreakEveryField.editorActive
    || longBreakSecondsField.editorActive
    || snoozeBudgetField.editorActive
    || maximumDelayField.editorActive
    || soundVolumeField.editorActive
  readonly property bool dropdownOpen: enforcementDropdown.popupOpen
    || officeStartDropdown.popupOpen || officeEndDropdown.popupOpen
    || outputModeDropdown.popupOpen || displayModeDropdown.popupOpen
  readonly property Item initialFocusTarget: settingsTabs
  readonly property Item finalFocusTarget: {
    var controls = targets()
    return controls.length ? controls[controls.length - 1] : settingsTabs
  }

  signal persistRequested(var values)
  signal pauseRequested()
  signal editRequested()
  signal closeRequested()

  Layout.fillWidth: true
  Layout.topMargin: Style.space(8)
  spacing: Style.space(10)

  function focusInitial() { settingsTabs.forceActiveFocus() }
  function reset() {
    settingsTab = "general"
    cursorActive = false
    cursorIndex = 0
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
      general: [pauseBreaksButton, editSettingsButton, officeHoursRow,
        officeStartDropdown, officeEndDropdown],
      context: [idleDetectionRow, fullscreenDetectionRow, mediaDetectionRow,
        microphoneDetectionRow, dictationDetectionRow],
      breaks: [focusMinutesField, shortBreakField, longBreakEveryField,
        longBreakSecondsField, snoozeBudgetField, maximumDelayField,
        enforcementDropdown],
      experience: [reduceMotionRow, soundRow, soundVolumeField, startSoundRow,
        completionSoundRow, outputModeDropdown, displayModeDropdown,
        keyboardHintRow]
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
  function moveCursor(delta) {
    if (cursorActive && delta < 0 && cursorIndex === 0) {
      cursorActive = false
      settingsTabs.forceActiveFocus()
      ensureCursorVisible(settingsTabs)
      return
    }
    setCursor(cursorActive ? cursorIndex + delta : 0)
  }
  function activateCursor() {
    if (!cursorActive) { setCursor(0); return }
    var target = targets()[cursorIndex]
    if (target && typeof target.activate === "function") target.activate()
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
  LookUi.SettingsTabBar {
    id: settingsTabs
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: settingsPage.topInset + Style.space(8)
    options: [
      { value: "general", label: qsTr("General"), key: Model.panelShortcutLabel(settingsPage.shortcuts.generalTab) },
      { value: "breaks", label: qsTr("Breaks"), key: Model.panelShortcutLabel(settingsPage.shortcuts.breaksTab) },
      { value: "context", label: qsTr("Context"), key: Model.panelShortcutLabel(settingsPage.shortcuts.contextTab) },
      { value: "experience", label: qsTr("Experience"), key: Model.panelShortcutLabel(settingsPage.shortcuts.experienceTab) }
    ]
    value: settingsPage.settingsTab
    hintsVisible: settingsPage.keyboardHintsVisible
    foreground: settingsPage.foreground
    background: Color.popups.background
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    fontSize: Style.font.bodySmall
    KeyNavigation.tab: settingsPage.settingsTab === "general" ? pauseBreaksButton
      : settingsPage.settingsTab === "context" ? idleDetectionRow
      : settingsPage.settingsTab === "breaks" ? focusMinutesField.field
      : reduceMotionRow
    Keys.onEscapePressed: settingsPage.dismissHintsOrClose()
    onDownRequested: {
      settingsPage.focusProxy.forceActiveFocus()
      settingsPage.setCursor(0)
    }
    onUpRequested: settingsPage.settingsButtonTarget.forceActiveFocus()
    onChanged: function(next) {
      settingsPage.settingsTab = next
      settingsPage.cursorActive = false
      settingsPage.scrollFlickable.contentY = 0
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "general"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    label: qsTr("App controls")
    foreground: settingsPage.muted
    fontFamily: settingsPage.fontFamily
  }

  LookUi.ToggleSettingRow {
    id: pauseBreaksButton
    Layout.fillWidth: true
    label: qsTr("Break reminders")
    description: qsTr("Temporarily pause break reminders")
    checked: !!settingsPage.service && !settingsPage.manuallyPaused
    enabled: !!settingsPage.service && Model.canTogglePause(settingsPage.service.phase)
    foreground: settingsPage.foreground
    muted: settingsPage.muted
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 0
    onHovered: function(on) { if (on) settingsPage.setCursor(0) }
    KeyNavigation.tab: editSettingsButton
    Keys.onEscapePressed: settingsPage.dismissHintsOrClose()
    onClicked: settingsPage.toggleManualPause()

    LookUi.KeyHintBadge {
      visible: settingsPage.keyboardHintsVisible
      keyText: Model.panelShortcutLabel(settingsPage.shortcuts.pause)
      available: pauseBreaksButton.enabled
      x: parent.controlX - width - Style.space(4)
      y: parent.controlY + (parent.controlHeight - height) / 2
    }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

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
      hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 1
      onHovered: function(on) { if (on) settingsPage.setCursor(1) }
      KeyNavigation.backtab: pauseBreaksButton
      Keys.onEscapePressed: settingsPage.dismissHintsOrClose()
      Accessible.role: Accessible.Button
      Accessible.name: qsTr("Open Omarchy Shell configuration file")
      Accessible.onPressAction: clicked()
      onClicked: settingsPage.editRequested()

    }

    LookUi.KeyHintBadge {
      visible: settingsPage.keyboardHintsVisible
      keyText: Model.panelShortcutLabel(settingsPage.shortcuts.edit)
      x: parent.width - width
      y: editSettingsButton.y - height / 2
    }
  }

  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "general"

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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 2
    onHovered: function(on) { if (on) settingsPage.setCursor(2) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 3
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(3) }
    onPopupClosed: if (settingsPage.active) Qt.callLater(function() { settingsPage.focusProxy.forceActiveFocus() })
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 4
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(4) }
    onPopupClosed: if (settingsPage.active) Qt.callLater(function() { settingsPage.focusProxy.forceActiveFocus() })
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 0
    onHovered: function(on) { if (on) settingsPage.setCursor(0) }
    onClicked: settingsPage.persistSettings({ idleDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: fullscreenDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect fullscreen work")
    description: qsTr("Delay a due break while fullscreen")
    checked: !settingsPage.settings || settingsPage.settings.fullscreenDetection === undefined || settingsPage.settings.fullscreenDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 1
    onHovered: function(on) { if (on) settingsPage.setCursor(1) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 2
    onHovered: function(on) { if (on) settingsPage.setCursor(2) }
    onClicked: settingsPage.persistSettings({ mediaDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: microphoneDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect microphone use")
    description: qsTr("Delay during calls without recording audio")
    checked: !settingsPage.settings || settingsPage.settings.microphoneDetection === undefined || settingsPage.settings.microphoneDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 3
    onHovered: function(on) { if (on) settingsPage.setCursor(3) }
    onClicked: settingsPage.persistSettings({ microphoneDetection: !checked })
  }
  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }
  LookUi.ToggleSettingRow {
    id: dictationDetectionRow
    Layout.fillWidth: true
    label: qsTr("Protect dictation")
    description: qsTr("Delay while Omarchy dictation is active")
    checked: !settingsPage.settings || settingsPage.settings.dictationDetection === undefined || settingsPage.settings.dictationDetection === true
    foreground: settingsPage.foreground; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 4
    onHovered: function(on) { if (on) settingsPage.setCursor(4) }
    onClicked: settingsPage.persistSettings({ dictationDetection: !checked })
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
      Text { width: parent.width; text: qsTr("Focus interval"); color: settingsPage.foreground; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
      Text { width: parent.width; text: qsTr("Minutes of active screen time between breaks"); color: settingsPage.muted; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
    }

    NumberField {
      id: focusMinutesField
      width: Style.space(72)
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      value: settingsPage.settings && settingsPage.settings.focusMinutes !== undefined ? Number(settingsPage.settings.focusMinutes) : 20
      from: 1
      to: 180
      fieldWidth: Style.space(72)
      foreground: settingsPage.foreground
      accent: settingsPage.accent
      fontFamily: settingsPage.fontFamily
      hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 0
      onHovered: function(on) { if (on) settingsPage.setCursor(0) }
      onModified: function(next) { settingsPage.persistSettings({ focusMinutes: next }) }
    }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

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
      Text { width: parent.width; text: qsTr("Short break"); color: settingsPage.foreground; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
      Text { width: parent.width; text: qsTr("Seconds for an ordinary eye break"); color: settingsPage.muted; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
    }

    NumberField {
      id: shortBreakField
      width: Style.space(72)
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      value: settingsPage.settings && settingsPage.settings.breakSeconds !== undefined ? Number(settingsPage.settings.breakSeconds) : 20
      from: 5
      to: 600
      stepSize: 5
      fieldWidth: Style.space(72)
      foreground: settingsPage.foreground
      accent: settingsPage.accent
      fontFamily: settingsPage.fontFamily
      hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 1
      onHovered: function(on) { if (on) settingsPage.setCursor(1) }
      onModified: function(next) { settingsPage.persistSettings({ breakSeconds: next }) }
    }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.NumberSettingRow {
    id: longBreakEveryField
    Layout.fillWidth: true
    label: qsTr("Long-break cadence")
    description: qsTr("Make every Nth break long; 0 disables it")
    value: settingsPage.settings && settingsPage.settings.longBreakEvery !== undefined ? Number(settingsPage.settings.longBreakEvery) : 4
    from: 0; to: 20
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 2
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(2) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 3
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(3) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 4
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(4) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 5
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(5) }
    onModified: function(next) { settingsPage.persistSettings({ maximumDelayMinutes: next }) }
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

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
      Text { width: parent.width; text: qsTr("Break enforcement"); color: settingsPage.foreground; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
      Text { width: parent.width; text: qsTr("Choose when an active break may be skipped"); color: settingsPage.muted; font.family: settingsPage.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
    }

    Dropdown {
      id: enforcementDropdown
      width: Style.space(132)
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      showLabel: false
      value: settingsPage.settings && settingsPage.settings.enforcement !== undefined ? String(settingsPage.settings.enforcement) : "balanced"
      options: [
        { value: "casual", label: qsTr("Casual") },
        { value: "balanced", label: qsTr("Balanced") },
        { value: "hardcore", label: qsTr("Hardcore") }
      ]
      foreground: settingsPage.foreground
      accent: settingsPage.accent
      fontFamily: settingsPage.fontFamily
      hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 6
      onPopupOpenChanged: if (!popupOpen && settingsPage.active)
        Qt.callLater(function() { settingsPage.focusProxy.forceActiveFocus() })
      onHovered: function(on) { if (on) settingsPage.setCursor(6) }
      onChanged: function(next) { settingsPage.persistSettings({ enforcement: next }) }
    }
  }

  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.space(10)
    visible: settingsPage.settingsTab === "experience"

  LookUi.SectionHeader {
    Layout.fillWidth: true
    Layout.topMargin: Style.space(8)
    label: qsTr("Experience")
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 0
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: clicked()
    onHovered: function(on) { if (on) settingsPage.setCursor(0) }
    KeyNavigation.tab: soundRow
    onClicked: settingsPage.persistSettings({ reducedMotion: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.ToggleSettingRow {
    id: soundRow
    Layout.fillWidth: true
    label: qsTr("Play break sounds")
    description: qsTr("Use the quiet start and completion cues")
    checked: !settingsPage.settings || settingsPage.settings.soundEnabled === undefined || settingsPage.settings.soundEnabled === true
    foreground: settingsPage.foreground
    accent: settingsPage.accent
    fontFamily: settingsPage.fontFamily
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 1
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: clicked()
    onHovered: function(on) { if (on) settingsPage.setCursor(1) }
    KeyNavigation.tab: soundVolumeField
    KeyNavigation.backtab: reduceMotionRow
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 2
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(2) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 3
    onHovered: function(on) { if (on) settingsPage.setCursor(3) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 4
    onHovered: function(on) { if (on) settingsPage.setCursor(4) }
    onClicked: settingsPage.persistSettings({ completionSoundEnabled: !checked })
  }

  PanelSeparator { Layout.fillWidth: true; foreground: settingsPage.foreground }

  LookUi.DropdownSettingRow {
    id: outputModeDropdown
    Layout.fillWidth: true
    label: qsTr("Break outputs")
    description: qsTr("Choose where full-screen breaks appear")
    value: settingsPage.settings && settingsPage.settings.outputMode !== undefined ? String(settingsPage.settings.outputMode) : "all"
    options: [{ value: "all", label: qsTr("All displays") }, { value: "focused", label: qsTr("Focused display") }]
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 5
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(5) }
    onPopupClosed: if (settingsPage.active) Qt.callLater(function() { settingsPage.focusProxy.forceActiveFocus() })
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 6
    foreground: settingsPage.foreground; muted: settingsPage.muted; accent: settingsPage.accent; fontFamily: settingsPage.fontFamily
    onHovered: function(on) { if (on) settingsPage.setCursor(6) }
    onPopupClosed: if (settingsPage.active) Qt.callLater(function() { settingsPage.focusProxy.forceActiveFocus() })
    onChanged: function(next) { settingsPage.persistSettings({ displayMode: next }) }
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
    hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex === 7
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.checked: checked
    Accessible.onPressAction: clicked()
    onHovered: function(on) { if (on) settingsPage.setCursor(7) }
    KeyNavigation.tab: settingsPage.shortcutsButtonTarget
    KeyNavigation.backtab: soundRow
    onClicked: settingsPage.persistSettings({ showKeyboardHints: !checked })
  }

  }
}

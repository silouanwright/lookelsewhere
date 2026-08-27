pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "../Model.js" as Model
import "../vendor/qmlpack/oma-ui-kit/Ui" as LookUi

ColumnLayout {
  id: root

  property var settings: ({})
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property int selectedIndex: 0
  property int selectedDayIndex: 0
  property string nameDraft: ""
  property string editingRoutineId: ""
  property var cursorTarget: null
  readonly property var routines: Model.normalizeConfig({
    plannedBreaks: settings && settings.plannedBreaks !== undefined ? settings.plannedBreaks : "[]"
  }).plannedBreaks
  readonly property var selectedRoutine: routines.length
    ? routines[Math.max(0, Math.min(selectedIndex, routines.length - 1))] : null
  readonly property bool editorActive: nameField.activeFocus || durationRow.editorActive
  readonly property bool dropdownOpen: routineRow.popupOpen || startRow.popupOpen
  readonly property Item routineTarget: routineRow
  readonly property Item enabledTarget: enabledRow
  readonly property Item nameTarget: nameRow
  readonly property Item startTarget: startRow
  readonly property Item durationTarget: durationRow
  readonly property Item daysTarget: daysRow
  readonly property Item addTarget: addButton
  readonly property Item removeTarget: removeButton

  signal persistRequested(var values)
  signal editorClosed()

  Layout.fillWidth: true
  spacing: Style.space(10)

  onRoutinesChanged: if (selectedIndex >= routines.length)
    selectedIndex = Math.max(0, routines.length - 1)
  onSelectedRoutineChanged: if (!nameField.activeFocus)
    nameDraft = selectedRoutine ? selectedRoutine.name : ""

  function cloneRoutines() { return JSON.parse(JSON.stringify(routines)) }
  function save(values) { persistRequested({ plannedBreaks: JSON.stringify(values) }) }
  function updateSelected(key, value) {
    if (!selectedRoutine) return
    let values = cloneRoutines()
    values[selectedIndex][key] = value
    save(values)
  }
  function updateRoutineById(id, key, value) {
    let values = cloneRoutines()
    for (let i = 0; i < values.length; i++) {
      if (values[i].id !== id) continue
      values[i][key] = value
      save(values)
      return
    }
  }
  function addRoutine() {
    if (routines.length >= 8) return
    let values = cloneRoutines()
    values.push({
      id: "planned-" + Date.now(), name: qsTr("Planned break"),
      startMinute: (12 * 60 + values.length * 30) % (24 * 60),
      durationMs: 30 * 60000, days: [1, 2, 3, 4, 5], enabled: true
    })
    selectedIndex = values.length - 1
    save(values)
  }
  function removeRoutine() {
    if (!selectedRoutine) return
    let values = cloneRoutines()
    values.splice(selectedIndex, 1)
    selectedIndex = Math.max(0, selectedIndex - 1)
    save(values)
  }
  function toggleDay(day) {
    if (!selectedRoutine) return
    let days = selectedRoutine.days.slice()
    let index = days.indexOf(day)
    if (index >= 0 && days.length > 1) days.splice(index, 1)
    else if (index < 0) days.push(day)
    days.sort(function(left, right) { return left - right })
    updateSelected("days", days)
  }
  function moveDays(delta) { selectedDayIndex = Math.max(0, Math.min(6, selectedDayIndex + delta)) }
  function clockOptions() {
    let values = []
    for (let halfHour = 0; halfHour < 48; halfHour++) {
      let hour = Math.floor(halfHour / 2)
      let minute = halfHour % 2 ? "30" : "00"
      let text = (hour < 10 ? "0" : "") + hour + ":" + minute
      values.push({ value: String(halfHour * 30), label: text })
    }
    return values
  }
  function routineOptions() {
    let values = []
    for (let i = 0; i < routines.length; i++)
      values.push({ value: String(i), label: routines[i].name })
    return values
  }

  LookUi.SectionHeader {
    Layout.fillWidth: true
    label: qsTr("Planned breaks")
    foreground: root.muted
    fontFamily: root.fontFamily
  }

  Text {
    Layout.fillWidth: true
    visible: !root.selectedRoutine
    text: qsTr("Add a routine for lunch, prayer, a walk, or any break that belongs at a particular time.")
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  LookUi.DropdownSettingRow {
    id: routineRow
    Layout.fillWidth: true
    visible: root.routines.length > 0
    label: qsTr("Routine")
    description: qsTr("Choose a planned break to edit")
    value: String(root.selectedIndex)
    options: root.routineOptions()
    hasCursor: root.cursorTarget === routineRow
    foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
    onChanged: function(next) { root.selectedIndex = Number(next) }
    onPopupClosed: root.editorClosed()
  }

  PanelSeparator { Layout.fillWidth: true; visible: root.routines.length > 0; foreground: root.foreground }

  LookUi.ToggleSettingRow {
    id: enabledRow
    Layout.fillWidth: true
    visible: !!root.selectedRoutine
    label: qsTr("Enabled")
    description: qsTr("Run this routine on its selected days")
    checked: root.selectedRoutine ? root.selectedRoutine.enabled : false
    hasCursor: root.cursorTarget === enabledRow
    foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
    onClicked: root.updateSelected("enabled", !checked)
  }

  PanelSeparator { Layout.fillWidth: true; visible: !!root.selectedRoutine; foreground: root.foreground }

  Item {
    id: nameRow
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(nameLabels.implicitHeight, nameField.implicitHeight)
    visible: !!root.selectedRoutine
    function activate() { nameField.forceActiveFocus(); nameField.selectAll() }

    LookUi.SettingLabels {
      id: nameLabels
      anchors.left: parent.left
      anchors.right: nameField.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      label: qsTr("Name")
      description: qsTr("Shown when the routine is due")
      foreground: root.foreground; muted: root.muted; fontFamily: root.fontFamily
    }
    TextField {
      id: nameField
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(132)
      text: root.nameDraft
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      selectByMouse: true
      background: Rectangle {
        color: "transparent"
        radius: Style.cornerRadius
        border.width: nameField.activeFocus || root.cursorTarget === nameRow ? Math.max(1, Style.normalBorderWidth) : 1
        border.color: nameField.activeFocus || root.cursorTarget === nameRow ? root.accent : Color.popups.border
      }
      onActiveFocusChanged: if (activeFocus) {
        root.editingRoutineId = root.selectedRoutine ? root.selectedRoutine.id : ""
        root.nameDraft = root.selectedRoutine ? root.selectedRoutine.name : ""
      }
      onTextEdited: root.nameDraft = text
      onEditingFinished: {
        root.updateRoutineById(root.editingRoutineId, "name", root.nameDraft)
        root.editingRoutineId = ""
        root.editorClosed()
      }
    }
  }

  PanelSeparator { Layout.fillWidth: true; visible: !!root.selectedRoutine; foreground: root.foreground }

  LookUi.DropdownSettingRow {
    id: startRow
    Layout.fillWidth: true
    visible: !!root.selectedRoutine
    label: qsTr("Starts")
    description: qsTr("Local time on the selected days")
    value: root.selectedRoutine ? String(root.selectedRoutine.startMinute) : "720"
    options: root.clockOptions()
    hasCursor: root.cursorTarget === startRow
    foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
    onChanged: function(next) { root.updateSelected("startMinute", Number(next)) }
    onPopupClosed: root.editorClosed()
  }

  PanelSeparator { Layout.fillWidth: true; visible: !!root.selectedRoutine; foreground: root.foreground }

  LookUi.NumberSettingRow {
    id: durationRow
    Layout.fillWidth: true
    visible: !!root.selectedRoutine
    label: qsTr("Duration")
    description: qsTr("Minutes reserved for this break")
    value: root.selectedRoutine ? Math.round(root.selectedRoutine.durationMs / 60000) : 30
    from: 1; to: 120
    hasCursor: root.cursorTarget === durationRow
    foreground: root.foreground; muted: root.muted; accent: root.accent; fontFamily: root.fontFamily
    onModified: function(next) { root.updateSelected("durationMs", next * 60000) }
  }

  PanelSeparator { Layout.fillWidth: true; visible: !!root.selectedRoutine; foreground: root.foreground }

  Item {
    id: daysRow
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(daysLabels.implicitHeight, dayButtons.implicitHeight)
    visible: !!root.selectedRoutine
    function activate() { root.toggleDay(root.selectedDayIndex) }

    LookUi.SettingLabels {
      id: daysLabels
      anchors.left: parent.left
      anchors.right: dayButtons.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      label: qsTr("Days")
      description: qsTr("Use Left and Right, then Enter")
      foreground: root.foreground; muted: root.muted; fontFamily: root.fontFamily
    }
    Row {
      id: dayButtons
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)
      Repeater {
        model: [qsTr("S"), qsTr("M"), qsTr("T"), qsTr("W"), qsTr("T"), qsTr("F"), qsTr("S")]
        delegate: LookUi.WeightedButton {
          required property string modelData
          required property int index
          label: modelData
          selected: root.selectedRoutine && root.selectedRoutine.days.indexOf(index) >= 0
          bordered: true
          horizontalPadding: Style.space(4)
          verticalPadding: Style.space(3)
          foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
          hasCursor: root.cursorTarget === daysRow && root.selectedDayIndex === index
          onClicked: root.toggleDay(index)
        }
      }
    }
  }

  PanelSeparator { Layout.fillWidth: true; visible: !!root.selectedRoutine; foreground: root.foreground }

  RowLayout {
    Layout.alignment: Qt.AlignRight
    spacing: Style.space(6)
    LookUi.WeightedButton {
      id: removeButton
      visible: !!root.selectedRoutine
      label: qsTr("Remove")
      bordered: true
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      hasCursor: root.cursorTarget === removeButton
      onClicked: root.removeRoutine()
    }
    LookUi.WeightedButton {
      id: addButton
      label: qsTr("Add routine")
      selected: true
      actionEnabled: root.routines.length < 8
      disabledTooltipText: qsTr("Eight planned breaks is the maximum")
      foreground: root.foreground; accent: root.accent; fontFamily: root.fontFamily
      hasCursor: root.cursorTarget === addButton
      onClicked: root.addRoutine()
    }
  }
}

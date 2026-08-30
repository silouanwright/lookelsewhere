import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "../vendor/qmlpack/oma-ui-kit/Ui" as LookUi

Item {
  id: root

  property string label: ""
  property string description: ""
  property string value: ""
  property bool hasCursor: false
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  readonly property bool editorActive: field.activeFocus
    || !!(field.contentItem && field.contentItem.activeFocus)

  signal modified(string value)
  signal hovered(bool on)

  function activate() { if (enabled) { field.forceActiveFocus(); field.selectAll() } }
  function focusEditor() { activate() }

  implicitHeight: Math.max(labels.implicitHeight, field.implicitHeight)

  LookUi.SettingLabels {
    id: labels
    anchors.left: parent.left
    anchors.right: field.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    label: root.label
    description: root.description
    foreground: root.foreground
    muted: root.muted
    fontFamily: root.fontFamily
  }

  TextField {
    id: field
    width: Style.space(160)
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    selectByMouse: true
    background: Rectangle {
      color: "transparent"
      radius: Style.cornerRadius
      border.width: field.activeFocus || rowHover.hovered || root.hasCursor
        ? Math.max(1, Style.normalBorderWidth) : 1
      border.color: field.activeFocus || rowHover.hovered || root.hasCursor
        ? root.accent : Color.popups.border
    }
    onEditingFinished: root.modified(text.trim())
    Accessible.name: root.label
    Accessible.description: root.description
  }

  Binding {
    target: field
    property: "text"
    value: root.value
    when: !root.editorActive
    restoreMode: Binding.RestoreNone
  }

  HoverHandler {
    id: rowHover
    onHoveredChanged: root.hovered(hovered)
  }

  MouseArea {
    anchors.left: parent.left
    anchors.right: field.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.rightMargin: Style.space(12)
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activate()
  }
}

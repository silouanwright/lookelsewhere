import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string label: ""
  property string description: ""
  property int value: 0
  property int from: 0
  property int to: 100
  property int stepSize: 1
  property bool hasCursor: false
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  readonly property bool editorActive: field.field.activeFocus || field.field.contentItem.activeFocus

  signal modified(int value)
  signal hovered(bool on)

  function activate() { if (enabled) field.field.forceActiveFocus() }
  function focusEditor() { activate() }

  implicitHeight: Math.max(labels.implicitHeight, field.implicitHeight)

  SettingLabels {
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

  NumberField {
    id: field
    width: Style.space(72)
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    value: root.value
    from: root.from
    to: root.to
    stepSize: root.stepSize
    fieldWidth: Style.space(72)
    foreground: root.foreground
    accent: root.accent
    fontFamily: root.fontFamily
    hasCursor: root.hasCursor || rowHover.hovered
    onModified: function(next) { root.modified(next) }

  }

  Binding { target: field.field.Accessible; property: "name"; value: root.label }
  Binding { target: field.field.Accessible; property: "description"; value: root.description }

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

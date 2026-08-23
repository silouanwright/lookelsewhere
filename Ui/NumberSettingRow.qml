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

  function focusEditor() { field.field.forceActiveFocus() }

  implicitHeight: Math.max(labels.implicitHeight, field.implicitHeight)

  Column {
    id: labels
    anchors.left: parent.left
    anchors.right: field.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    Text { width: parent.width; text: root.label; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
    Text { width: parent.width; text: root.description; color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
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
    hasCursor: root.hasCursor
    onHovered: function(on) { root.hovered(on) }
    onModified: function(next) { root.modified(next) }
  }
}

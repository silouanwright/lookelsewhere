import QtQuick
import qs.Commons

Rectangle {
  id: root

  required property string keyText
  property bool available: true

  readonly property real badgeSize: Style.space(12)

  anchors.top: parent.top
  anchors.right: parent.right
  anchors.topMargin: 0
  anchors.rightMargin: 0
  implicitWidth: keyText.length === 1
    ? badgeSize
    : Math.max(badgeSize, label.implicitWidth + Style.space(5))
  implicitHeight: badgeSize
  radius: height / 2
  color: Color.accent
  opacity: available ? 1 : 0.45
  z: 20

  Text {
    id: label
    anchors.centerIn: parent
    text: root.keyText
    color: Style.selectedStateColor(Color.popups.text, Color.accent)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.weight: Font.Bold
  }
}

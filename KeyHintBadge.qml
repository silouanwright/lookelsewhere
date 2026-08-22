import QtQuick
import qs.Commons

Rectangle {
  id: root

  required property string keyText
  property bool available: true

  anchors.top: parent.top
  anchors.right: parent.right
  anchors.topMargin: -Style.space(5)
  anchors.rightMargin: -Style.space(4)
  implicitWidth: label.implicitWidth + Style.space(6)
  implicitHeight: label.implicitHeight + Style.space(2)
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

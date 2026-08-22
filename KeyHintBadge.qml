import QtQuick
import qs.Commons

Rectangle {
  id: root

  required property string keyText
  property bool available: true
  property bool placeRight: false
  property bool centerOnCorner: false

  readonly property real badgeSize: Style.space(14)

  x: placeRight ? parent.width + Style.space(3)
    : (centerOnCorner ? -width / 2 : (parent.width - width) / 2)
  y: placeRight ? (parent.height - height) / 2
    : (centerOnCorner ? -height / 2 : parent.height + Style.space(2))
  implicitWidth: keyText.length === 1
    ? badgeSize
    : Math.max(badgeSize, label.implicitWidth + Style.space(5))
  implicitHeight: badgeSize
  radius: height / 2
  color: Color.popups.text
  opacity: available ? 1 : 0.6
  z: 20

  Text {
    id: label
    anchors.centerIn: parent
    text: root.keyText
    color: Color.popups.background
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.weight: Font.Bold
  }
}

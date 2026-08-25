import QtQuick
import qs.Commons

Rectangle {
  id: root

  required property string keyText
  property bool available: true
  property bool placeRight: false
  property bool centerOnCorner: false
  property bool customPosition: false
  property real customX: 0
  property real customY: 0

  readonly property real badgeSize: Style.space(14)
  readonly property bool shiftChord: /^⬆.$/.test(keyText)
  readonly property real keyWidth: shiftChord ? shiftRow.implicitWidth : label.implicitWidth

  x: customPosition ? customX : placeRight ? parent.width + Style.space(3)
    : (centerOnCorner ? parent.width - width / 2 : (parent.width - width) / 2)
  y: customPosition ? customY : placeRight ? (parent.height - height) / 2
    : (centerOnCorner ? -height / 2 : parent.height + Style.space(2))
  implicitWidth: keyText.length === 1
    ? badgeSize
    : Math.max(badgeSize, keyWidth + Style.space(5))
  implicitHeight: badgeSize
  radius: height / 2
  color: Color.popups.text
  opacity: available ? 1 : 0.6
  z: 20

  Text {
    id: label
    anchors.centerIn: parent
    visible: !root.shiftChord
    text: root.keyText
    color: Color.popups.background
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.weight: Font.Bold
  }

  Row {
    id: shiftRow
    anchors.centerIn: parent
    visible: root.shiftChord
    spacing: Style.space(1)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "⬆"
      color: Color.popups.background
      font.family: Style.font.family
      font.pixelSize: Style.font.caption * 0.72
      font.weight: Font.Bold
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.keyText.slice(1)
      color: Color.popups.background
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: Font.Bold
    }
  }
}

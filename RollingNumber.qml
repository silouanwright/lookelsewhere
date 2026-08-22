pragma ComponentBehavior: Bound

import QtQuick

Item {
  id: root

  property int value: 0
  property color color: "white"
  property string fontFamily: ""
  property real fontSize: 24
  property int fontWeight: Font.Normal
  property bool reducedMotion: false
  property bool animationActive: true
  property int minimumDigits: 1

  readonly property int safeValue: Math.max(0, Math.floor(Number(value)))
  readonly property int digitCount: Math.max(minimumDigits, String(safeValue).length)

  implicitWidth: digits.implicitWidth
  implicitHeight: digits.implicitHeight

  Row {
    id: digits
    anchors.fill: parent
    spacing: 0

    Repeater {
      model: root.digitCount

      RollingDigit {
        required property int index
        readonly property int place: root.digitCount - index - 1
        value: Math.floor(root.safeValue / Math.pow(10, place)) % 10
        color: root.color
        fontFamily: root.fontFamily
        fontSize: root.fontSize
        fontWeight: root.fontWeight
        reducedMotion: root.reducedMotion
        animationActive: root.animationActive
      }
    }
  }
}

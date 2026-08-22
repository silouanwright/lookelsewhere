import QtQuick

Item {
  id: root

  property int value: 0
  property color color: "white"
  property string fontFamily: ""
  property real fontSize: 24
  property int fontWeight: Font.Normal
  property bool reducedMotion: false

  property int currentValue: -1
  property int previousValue: -1
  property real reveal: 1

  function syncValue() {
    var next = Math.max(0, Math.min(9, Number(value)))
    if (currentValue < 0 || reducedMotion) {
      roll.stop()
      previousValue = -1
      currentValue = next
      reveal = 1
      return
    }
    if (currentValue === next) return
    roll.stop()
    previousValue = currentValue
    currentValue = next
    reveal = 0
    roll.start()
  }

  onValueChanged: syncValue()
  onReducedMotionChanged: if (reducedMotion) syncValue()
  Component.onCompleted: syncValue()

  implicitWidth: Math.max(incoming.implicitWidth, outgoing.implicitWidth)
  implicitHeight: Math.max(incoming.implicitHeight, outgoing.implicitHeight)
  clip: true

  Text {
    id: outgoing
    anchors.horizontalCenter: parent.horizontalCenter
    y: -root.reveal * root.height
    text: root.previousValue < 0 ? "" : String(root.previousValue)
    color: root.color
    opacity: 1 - root.reveal
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.fontWeight
    renderType: Text.NativeRendering
    Accessible.ignored: true
  }

  Text {
    id: incoming
    anchors.horizontalCenter: parent.horizontalCenter
    y: (1 - root.reveal) * root.height
    text: root.currentValue < 0 ? "" : String(root.currentValue)
    color: root.color
    opacity: root.reveal
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.fontWeight
    renderType: Text.NativeRendering
    Accessible.ignored: true
  }

  NumberAnimation {
    id: roll
    target: root
    property: "reveal"
    from: 0
    to: 1
    duration: 280
    easing.type: Easing.OutCubic
    alwaysRunToEnd: true
    onFinished: root.previousValue = -1
  }
}

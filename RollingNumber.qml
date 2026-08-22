import QtQuick

Item {
  id: root

  property int value: 0
  property color color: "white"
  property string fontFamily: ""
  property real fontSize: 24
  property int fontWeight: Font.Normal
  property bool reducedMotion: false

  readonly property string valueText: String(Math.max(0, value))
  property string currentText: ""
  property string previousText: ""
  property real reveal: 1

  function syncValue() {
    if (currentText === "" || reducedMotion) {
      roll.stop()
      previousText = ""
      currentText = valueText
      reveal = 1
      return
    }
    if (currentText === valueText) return
    roll.stop()
    previousText = currentText
    currentText = valueText
    reveal = 0
    roll.start()
  }

  onValueTextChanged: syncValue()
  onReducedMotionChanged: if (reducedMotion) syncValue()
  Component.onCompleted: syncValue()

  implicitWidth: Math.max(incoming.implicitWidth, outgoing.implicitWidth)
  implicitHeight: Math.max(incoming.implicitHeight, outgoing.implicitHeight)
  clip: true

  Text {
    id: outgoing
    anchors.horizontalCenter: parent.horizontalCenter
    y: -root.reveal * root.height
    text: root.previousText
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
    text: root.currentText
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
    onFinished: root.previousText = ""
  }
}

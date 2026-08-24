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

  property int currentValue: -1
  property int previousValue: -1

  readonly property bool animating: roll.running

  function settle() {
    outgoing.y = -root.height
    outgoing.opacity = 0
    incoming.y = 0
    incoming.opacity = 1
  }

  function syncValue() {
    var next = Math.max(0, Math.min(9, Number(value)))
    if (currentValue < 0 || reducedMotion || !animationActive) {
      roll.stop()
      previousValue = -1
      currentValue = next
      settle()
      return
    }
    if (currentValue === next) return
    roll.stop()
    previousValue = currentValue
    currentValue = next
    outgoing.y = 0
    outgoing.opacity = 1
    incoming.y = root.height
    incoming.opacity = 0
    roll.start()
  }

  onValueChanged: syncValue()
  onReducedMotionChanged: if (reducedMotion) syncValue()
  onAnimationActiveChanged: syncValue()
  Component.onCompleted: syncValue()

  implicitWidth: Math.max(incoming.implicitWidth, outgoing.implicitWidth)
  // Native font rasterization can extend one pixel below Text.implicitHeight.
  // Keep the rolling clip without shaving the bottom edge of the glyph.
  implicitHeight: Math.ceil(Math.max(incoming.implicitHeight, outgoing.implicitHeight)) + 1
  clip: true

  Text {
    id: outgoing
    anchors.horizontalCenter: parent.horizontalCenter
    y: -root.height
    text: root.previousValue < 0 ? "" : String(root.previousValue)
    color: root.color
    opacity: 0
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.fontWeight
    renderType: Text.NativeRendering
    Accessible.ignored: true
  }

  Text {
    id: incoming
    anchors.horizontalCenter: parent.horizontalCenter
    y: 0
    text: root.currentValue < 0 ? "" : String(root.currentValue)
    color: root.color
    opacity: 1
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.fontWeight
    renderType: Text.NativeRendering
    Accessible.ignored: true
  }

  // Animator types run on Qt Quick's render thread, so a busy Quickshell UI
  // thread does not make the ticker visibly freeze halfway through a roll.
  ParallelAnimation {
    id: roll
    YAnimator {
      target: outgoing
      from: 0
      to: -root.height
      duration: 280
      easing.type: Easing.OutCubic
    }
    OpacityAnimator {
      target: outgoing
      from: 1
      to: 0
      duration: 210
      easing.type: Easing.OutCubic
    }
    YAnimator {
      target: incoming
      from: root.height
      to: 0
      duration: 280
      easing.type: Easing.OutCubic
    }
    OpacityAnimator {
      target: incoming
      from: 0
      to: 1
      duration: 240
      easing.type: Easing.OutCubic
    }
    onFinished: {
      root.settle()
      root.previousValue = -1
    }
  }
}

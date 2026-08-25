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
  property int maximumSequentialGap: 3
  property int displayedValue: safeValue

  readonly property int safeValue: Math.max(0, Math.floor(Number(value)))
  readonly property int digitCount: Math.max(minimumDigits, String(displayedValue).length)

  function syncDisplayedValue() {
    var gap = displayedValue - safeValue
    if (!animationActive || reducedMotion || gap <= 1 || gap > maximumSequentialGap) {
      catchUp.stop()
      displayedValue = safeValue
      return
    }
    if (!catchUp.running) catchUp.start()
  }

  onSafeValueChanged: syncDisplayedValue()
  onAnimationActiveChanged: syncDisplayedValue()
  onReducedMotionChanged: syncDisplayedValue()
  Component.onCompleted: syncDisplayedValue()

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
        value: Math.floor(root.displayedValue / Math.pow(10, place)) % 10
        color: root.color
        fontFamily: root.fontFamily
        fontSize: root.fontSize
        fontWeight: root.fontWeight
        reducedMotion: root.reducedMotion
        animationActive: root.animationActive
      }
    }
  }

  // QML's event loop can occasionally miss a wall-clock sample under load.
  // Preserve timestamp authority while visually traversing a small missed gap
  // instead of making the rolling ticker jump over a number.
  Timer {
    id: catchUp
    // Leave the recovered value visibly settled after RollingDigit's 280 ms
    // animation. Equal durations can replace it on the animation's final frame.
    interval: 420
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (root.displayedValue <= root.safeValue) {
        stop()
        return
      }
      root.displayedValue--
      if (root.displayedValue <= root.safeValue) stop()
    }
  }
}

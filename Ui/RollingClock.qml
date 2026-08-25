import QtQuick

Row {
  id: root

  property int value: 0
  property color color: "white"
  property string fontFamily: ""
  property real fontSize: 24
  property int fontWeight: Font.Normal
  property bool reducedMotion: false
  property bool animationActive: true
  property real separatorOverlap: 0
  property int displayedValue: safeValue

  readonly property int safeValue: Math.max(0, Math.floor(Number(value)))
  readonly property int minutes: Math.floor(displayedValue / 60)
  readonly property int seconds: displayedValue % 60

  function syncDisplayedValue() {
    let missed = displayedValue - safeValue
    if (!animationActive || reducedMotion || missed <= 1) {
      catchUp.stop()
      displayedValue = safeValue
    } else if (!catchUp.running) {
      catchUp.start()
    }
  }

  onSafeValueChanged: syncDisplayedValue()
  onAnimationActiveChanged: syncDisplayedValue()
  onReducedMotionChanged: syncDisplayedValue()
  Component.onCompleted: syncDisplayedValue()

  spacing: -separatorOverlap

  RollingNumber {
    value: root.minutes
    minimumDigits: 2
    maximumSequentialGap: 0
    color: root.color
    fontFamily: root.fontFamily
    fontSize: root.fontSize
    fontWeight: root.fontWeight
    reducedMotion: root.reducedMotion
    animationActive: root.animationActive
  }

  Text {
    text: ":"
    color: root.color
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.fontWeight
    Accessible.ignored: true
  }

  RollingNumber {
    value: root.seconds
    minimumDigits: 2
    maximumSequentialGap: 0
    color: root.color
    fontFamily: root.fontFamily
    fontSize: root.fontSize
    fontWeight: root.fontWeight
    reducedMotion: root.reducedMotion
    animationActive: root.animationActive
  }

  // Keep one authoritative countdown queue across the minute boundary. The
  // old independent minute/second queues could not distinguish 01:00 -> 00:58
  // from an ordinary seconds reset and visibly dropped 00:59.
  Timer {
    id: catchUp
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

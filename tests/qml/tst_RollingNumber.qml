import QtQuick
import QtTest

import "../../Ui"

Item {
  id: root
  width: 240
  height: 120

  Component {
    id: numberComponent
    RollingNumber {
      width: implicitWidth
      height: implicitHeight
    }
  }

  Component {
    id: clockComponent
    RollingClock {
      width: implicitWidth
      height: implicitHeight
    }
  }

  TestCase {
    name: "RollingNumber"
    when: windowShown

    function test_digitCountTracksValueWidth() {
      let number = createTemporaryObject(numberComponent, root)
      verify(!!number, "Component exists")
      number.value = 9
      compare(number.digitCount, 1)
      number.value = 10
      compare(number.digitCount, 2)
      number.value = 100
      compare(number.digitCount, 3)
      number.value = 9
      compare(number.digitCount, 1)
    }

    function test_minimumDigitsAreRetained() {
      let number = createTemporaryObject(numberComponent, root)
      verify(!!number, "Component exists")
      number.minimumDigits = 2
      number.value = 0
      compare(number.digitCount, 2)
      number.value = 100
      compare(number.digitCount, 3)
    }

    function test_animationPolicyIsWritable() {
      let number = createTemporaryObject(numberComponent, root)
      verify(!!number, "Component exists")
      number.animationActive = false
      compare(number.animationActive, false)
      number.reducedMotion = true
      compare(number.reducedMotion, true)
    }

    function test_smallMissedCountdownGapIsTraversedSequentially() {
      let number = createTemporaryObject(numberComponent, root, {
        value: 6,
        animationActive: true,
        reducedMotion: false
      })
      verify(!!number, "Component exists")
      compare(number.displayedValue, 6)

      number.value = 4
      tryCompare(number, "displayedValue", 5)
      wait(300)
      compare(number.displayedValue, 5)
      tryCompare(number, "displayedValue", 4, 700)
    }

    function test_largeResetSnapsInsteadOfCountingThrough() {
      let number = createTemporaryObject(numberComponent, root, {
        value: 20,
        animationActive: true,
        reducedMotion: false
      })
      verify(!!number, "Component exists")
      number.value = 5
      compare(number.displayedValue, 5)
    }
  }

  TestCase {
    name: "RollingClock"
    when: windowShown

    function test_missedMinuteBoundaryKeepsIntermediateSecond() {
      let clock = createTemporaryObject(clockComponent, root, {
        value: 60,
        animationActive: true,
        reducedMotion: false
      })
      verify(!!clock, "Component exists")
      compare(clock.displayedValue, 60)

      clock.value = 58
      tryCompare(clock, "displayedValue", 59)
      wait(300)
      compare(clock.displayedValue, 59)
      tryCompare(clock, "displayedValue", 58, 700)
    }

    function test_longerVisibleStallDoesNotDropSeconds() {
      let clock = createTemporaryObject(clockComponent, root, {
        value: 60,
        animationActive: true,
        reducedMotion: false
      })
      verify(!!clock, "Component exists")
      let values = []
      clock.displayedValueChanged.connect(function() { values.push(clock.displayedValue) })

      clock.value = 55
      tryCompare(clock, "displayedValue", 55, 2400)
      compare(values.join(","), "59,58,57,56,55")
    }
  }
}

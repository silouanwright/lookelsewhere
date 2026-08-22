import QtQuick
import QtTest

import "../.."

Item {
  id: root
  width: 200
  height: 120

  Component {
    id: digitComponent
    RollingDigit {
      width: 80
      height: 80
    }
  }

  TestCase {
    name: "RollingDigit"
    when: windowShown

    function test_inactiveChangesSnapWithoutAnimation() {
      let digit = createTemporaryObject(digitComponent, root)
      verify(!!digit, "Component exists")
      digit.animationActive = false
      digit.value = 7
      compare(digit.currentValue, 7)
      compare(digit.previousValue, -1)
      compare(digit.reveal, 1)
    }

    function test_activeChangesCompleteAnimation() {
      let digit = createTemporaryObject(digitComponent, root)
      verify(!!digit, "Component exists")
      digit.animationActive = false
      digit.value = 4
      digit.animationActive = true
      digit.value = 5
      compare(digit.currentValue, 5)
      compare(digit.previousValue, 4)
      tryCompare(digit, "reveal", 1)
      compare(digit.previousValue, -1)
    }

    function test_reducedMotionSnapsWhileActive() {
      let digit = createTemporaryObject(digitComponent, root)
      verify(!!digit, "Component exists")
      digit.reducedMotion = true
      digit.value = 9
      compare(digit.currentValue, 9)
      compare(digit.previousValue, -1)
      compare(digit.reveal, 1)
    }
  }
}

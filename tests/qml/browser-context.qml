import QtQuick
import Quickshell
import "../.." as Plugin

ShellRoot {
  Loader {
    id: loader
    sourceComponent: Plugin.BrowserContext {
      onContextReceived: function(line) {
        console.log("RECEIVER_CONTEXT " + line)
        loader.active = false
        finish.start()
      }
    }
  }
  Timer {
    id: finish
    interval: 200
    onTriggered: Qt.quit()
  }
  Timer {
    interval: 5000
    running: true
    onTriggered: Qt.exit(1)
  }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property string pending: ""
  property int restartCount: 0
  readonly property string helperPath: decodeURIComponent(
    String(Qt.resolvedUrl("browser-extension/native-host/context_receiver.py")).replace(/^file:\/\//, ""))

  signal contextReceived(string line)
  signal unavailable()

  Process {
    id: receiver
    command: ["/usr/bin/python3", "-B", "-E", "-s", root.helperPath]
    clearEnvironment: true
    environment: ({ "XDG_RUNTIME_DIR": Quickshell.env("XDG_RUNTIME_DIR") })
    running: true
    stdout: SplitParser {
      // The helper emits only ASCII, <= 1 KiB per frame, at most four times
      // per second. Never use newline buffering on external socket traffic.
      splitMarker: ""
      onRead: function(chunk) {
        var start = 0
        while (start < chunk.length) {
          var end = chunk.indexOf("\n", start)
          var stop = end < 0 ? chunk.length : end
          if (root.pending.length + stop - start > 1024) {
            root.pending = ""
            receiver.signal(9)
            return
          }
          root.pending += chunk.slice(start, stop)
          if (end < 0) return
          root.contextReceived(root.pending)
          root.pending = ""
          start = end + 1
        }
      }
    }
    onExited: {
      root.pending = ""
      root.unavailable()
      // A reload may start the new helper just before the old Process is
      // destroyed. Allow that handover, without an unlimited crash loop.
      if (root.restartCount < 3) {
        root.restartCount++
        restartTimer.start()
      }
    }
  }

  Timer {
    id: restartTimer
    interval: 500
    onTriggered: receiver.running = true
  }

  Component.onDestruction: receiver.signal(15)
}

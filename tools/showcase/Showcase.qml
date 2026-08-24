import QtQuick
import Quickshell
import qs.Commons
import "LookElsewhere"

ShellRoot {
  id: shell

  readonly property string surface: Quickshell.env("LOOKELSEWHERE_SHOWCASE_SURFACE") || "panel"
  readonly property string outputPath: Quickshell.env("LOOKELSEWHERE_SHOWCASE_OUTPUT")
  readonly property string backgroundPath: Quickshell.env("LOOKELSEWHERE_SHOWCASE_BACKGROUND")
  readonly property int requestedWidth: Math.max(1, Number(Quickshell.env("LOOKELSEWHERE_SHOWCASE_WIDTH")) || 1920)
  readonly property int requestedHeight: Math.max(1, Number(Quickshell.env("LOOKELSEWHERE_SHOWCASE_HEIGHT")) || 1080)
  readonly property real density: Math.max(1, Number(Quickshell.env("LOOKELSEWHERE_SHOWCASE_DENSITY")) || 2)
  readonly property int cornerRadius: Math.max(0, Number(Quickshell.env("LOOKELSEWHERE_SHOWCASE_RADIUS")) || 0)

  FloatingWindow {
    id: window
    implicitWidth: canvas.width
    implicitHeight: canvas.height
    visible: true
    color: "transparent"

    Item {
      id: canvas
      width: shell.surface === "panel" ? panel.implicitWidth : shell.requestedWidth
      height: shell.surface === "panel" ? panel.implicitHeight : shell.requestedHeight

      ShowcasePanel {
        id: panel
        visible: shell.surface === "panel"
        cornerRadius: shell.cornerRadius
      }

      Item {
        anchors.fill: parent
        visible: shell.surface === "fullscreen"

        Rectangle {
          anchors.fill: parent
          color: Color.background
        }

        Image {
          anchors.fill: parent
          visible: shell.backgroundPath !== ""
          source: shell.backgroundPath === "" ? "" : "file://" + shell.backgroundPath
          sourceSize: Qt.size(shell.requestedWidth, shell.requestedHeight)
          fillMode: Image.PreserveAspectCrop
        }

        Rectangle {
          anchors.fill: parent
          color: Color.lock.background
        }

        BreakContent {
          anchors.centerIn: parent
          width: Math.min(parent.width - Style.space(48), Style.space(520))
          title: qsTr("Look elsewhere")
          subtitle: qsTr("Let your eyes settle on something distant. Breathe. The screen will still be here.")
          longBreak: true
          minutes: 3
          seconds: 0
          reducedMotion: true
          actionsVisible: true
          skipVisible: true
          skipEnabled: true
          postponeVisible: true
          clockFontSize: Style.font.display * 1.35
        }
      }
    }

    Timer {
      interval: 900
      running: true
      onTriggered: {
        Style.cornerRadius = shell.cornerRadius
        canvas.grabToImage(function(result) {
          if (!result.saveToFile(shell.outputPath)) Qt.exit(2)
          else Qt.quit()
        }, Qt.size(Math.round(canvas.width * shell.density), Math.round(canvas.height * shell.density)))
      }
    }
  }
}

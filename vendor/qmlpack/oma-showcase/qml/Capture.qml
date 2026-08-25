import QtQuick
import Quickshell
import "." as PreviewModule

ShellRoot {
  id: shell

  readonly property string outputPath: Quickshell.env("OMA_SHOWCASE_OUTPUT")
  readonly property real density: Math.max(1, Number(Quickshell.env("OMA_SHOWCASE_DENSITY")) || 2)

  FloatingWindow {
    implicitWidth: preview.implicitWidth
    implicitHeight: preview.implicitHeight
    visible: true
    color: "transparent"

    PreviewModule.Preview {
      id: preview
    }

    Timer {
      interval: 900
      running: true
      onTriggered: preview.grabToImage(function(result) {
        if (!result.saveToFile(shell.outputPath)) Qt.exit(2)
        else Qt.quit()
      }, Qt.size(Math.round(preview.width * shell.density), Math.round(preview.height * shell.density)))
    }
  }
}

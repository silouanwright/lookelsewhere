import QtQuick
import Quickshell
import qs.Commons
import "Project/Views" as ProductViews
import "Project/tools/showcase" as Showcase

Item {
  id: preview

  readonly property string surface: Quickshell.env("LOOKELSEWHERE_SHOWCASE_SURFACE") || "panel"
  readonly property string backgroundPath: Quickshell.env("OMA_SHOWCASE_BACKGROUND")
  readonly property int requestedWidth: Math.max(1, Number(Quickshell.env("OMA_SHOWCASE_WIDTH")) || 1920)
  readonly property int requestedHeight: Math.max(1, Number(Quickshell.env("OMA_SHOWCASE_HEIGHT")) || 1080)
  readonly property int cornerRadius: Math.max(0, Number(Quickshell.env("LOOKELSEWHERE_SHOWCASE_RADIUS")) || 0)
  readonly property string panelPattern: Quickshell.env("LOOKELSEWHERE_SHOWCASE_PATTERN") || "off"

  implicitWidth: surface === "panel" ? panel.implicitWidth : requestedWidth
  implicitHeight: surface === "panel" ? panel.implicitHeight : requestedHeight

  Showcase.ShowcasePanel {
    id: panel
    visible: preview.surface === "panel"
    cornerRadius: preview.cornerRadius
    pattern: preview.panelPattern
  }

  Item {
    anchors.fill: parent
    visible: preview.surface === "fullscreen"

    Rectangle {
      anchors.fill: parent
      color: Color.background
    }

    Image {
      anchors.fill: parent
      visible: preview.backgroundPath !== ""
      source: preview.backgroundPath === "" ? "" : "file://" + preview.backgroundPath
      sourceSize: Qt.size(preview.requestedWidth, preview.requestedHeight)
      fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
      anchors.fill: parent
      color: Color.lock.background
    }

    ProductViews.BreakContent {
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

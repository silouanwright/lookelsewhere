import QtQuick
import qs.Commons

Item {
  id: root

  property url source
  property size tileSize: Qt.size(64, 64)
  property color backgroundColor: Color.popups.background
  property real patternOpacity: 0.035

  Accessible.ignored: true

  readonly property bool hasPattern: source.toString().length > 0

  Image {
    anchors.fill: parent
    visible: root.hasPattern
    source: root.source
    sourceSize: root.tileSize
    fillMode: Image.Tile
    opacity: root.patternOpacity
  }

  Rectangle {
    anchors.fill: parent
    visible: root.hasPattern
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.00; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.36) }
      GradientStop { position: 0.18; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.04) }
      GradientStop { position: 0.48; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.44) }
      GradientStop { position: 0.76; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.00) }
      GradientStop { position: 1.00; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.28) }
    }
  }

  Rectangle {
    anchors.fill: parent
    visible: root.hasPattern
    gradient: Gradient {
      GradientStop { position: 0.00; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.22) }
      GradientStop { position: 0.42; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.00) }
      GradientStop { position: 0.72; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.18) }
      GradientStop { position: 1.00; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.02) }
    }
  }
}

import QtQuick
import qs.Commons

Item {
  id: root

  property string pattern: "off"

  Accessible.ignored: true

  readonly property var patterns: ["topography", "graph-paper", "wiggle",
    "bank-note", "diagonal-lines"]
  readonly property string assetName: patterns.indexOf(pattern) >= 0 ? pattern : ""
  readonly property color backgroundColor: Color.popups.background
  readonly property real backgroundLuminance: 0.2126 * backgroundColor.r
                                             + 0.7152 * backgroundColor.g
                                             + 0.0722 * backgroundColor.b

  Image {
    anchors.fill: parent
    visible: root.assetName !== ""
    source: !visible ? "" : "../assets/" + root.assetName
      + (root.backgroundLuminance > 0.5 ? "" : "-light") + ".svg"
    fillMode: Image.Tile
    opacity: 0.035
  }

  Rectangle {
    anchors.fill: parent
    visible: root.assetName !== ""
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
    visible: root.assetName !== ""
    gradient: Gradient {
      GradientStop { position: 0.00; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.22) }
      GradientStop { position: 0.42; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.00) }
      GradientStop { position: 0.72; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.18) }
      GradientStop { position: 1.00; color: Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, 0.02) }
    }
  }
}

import QtQuick
import qs.Commons
import "../vendor/qmlpack/oma-ui-kit/Ui" as OmaUi

Item {
  id: root

  property string pattern: "off"

  Accessible.ignored: true

  readonly property var patterns: ["topography", "graph-paper", "wiggle",
    "bank-note", "diagonal-lines"]
  readonly property string assetName: patterns.indexOf(pattern) >= 0 ? pattern : ""
  readonly property size assetSize: assetName === "topography" ? Qt.size(600, 600)
    : assetName === "graph-paper" ? Qt.size(100, 100)
    : assetName === "wiggle" ? Qt.size(52, 26)
    : assetName === "bank-note" ? Qt.size(100, 20)
    : Qt.size(6, 6)
  readonly property color backgroundColor: Color.popups.background
  readonly property real backgroundLuminance: 0.2126 * backgroundColor.r
                                             + 0.7152 * backgroundColor.g
                                             + 0.0722 * backgroundColor.b

  OmaUi.PanelPattern {
    anchors.fill: parent
    source: root.assetName === "" ? "" : Qt.resolvedUrl("../assets/" + root.assetName
      + (root.backgroundLuminance > 0.5 ? "" : "-light") + ".svg")
    visible: root.assetName !== ""
    backgroundColor: root.backgroundColor
    patternOpacity: 0.035
    tileSize: root.assetSize
  }
}

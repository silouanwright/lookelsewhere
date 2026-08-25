import QtQuick
import "../../oma-ui-kit/Ui" as OmaUi

Item {
  id: root

  required property CommandLayer commandLayer
  required property string keyText
  property bool available: true
  property bool placeRight: false
  property bool centerOnCorner: false

  anchors.fill: parent
  visible: commandLayer.hintsVisible
  z: 20

  OmaUi.KeyHintBadge {
    keyText: root.keyText
    available: root.available
    placeRight: root.placeRight
    centerOnCorner: root.centerOnCorner
  }
}

import QtQuick
import "../../oma-ui-kit/Ui" as OmaUi

Item {
  id: root

  required property CommandLayer commandLayer
  required property string keyText
  property bool available: true
  property bool placeRight: false
  property bool centerOnCorner: false
  property bool customPosition: false
  property real badgeX: 0
  property real badgeY: 0
  readonly property real badgeWidth: badge.implicitWidth
  readonly property real badgeHeight: badge.implicitHeight

  anchors.fill: parent
  visible: commandLayer.hintsVisible
  z: 20

  OmaUi.KeyHintBadge {
    id: badge
    keyText: root.keyText
    available: root.available
    placeRight: root.placeRight
    centerOnCorner: root.centerOnCorner
    customPosition: root.customPosition
    customX: root.badgeX
    customY: root.badgeY
  }
}

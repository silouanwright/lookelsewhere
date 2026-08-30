import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

RowLayout {
  id: root

  required property string label
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family

  spacing: Style.space(8)
  Accessible.role: Accessible.Heading
  Accessible.name: root.label

  Text {
    text: root.label
    color: root.foreground
    font {
      family: root.fontFamily
      pixelSize: Style.font.bodySmall
      weight: Font.DemiBold
    }
    Accessible.ignored: true
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: 1

    PanelSeparator {
      foreground: root.foreground
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}

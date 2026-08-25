import QtQuick
import qs.Commons

Column {
  id: root

  property string label: ""
  property string description: ""
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property string fontFamily: Style.font.family

  spacing: Style.space(2)

  Text {
    width: parent.width
    text: root.label
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
    font.weight: Font.DemiBold
    elide: Text.ElideRight
  }

  Text {
    width: parent.width
    text: root.description
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }
}

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  default property alias contentData: content.data
  property int horizontalPadding: Style.space(12)
  property int verticalPadding: Style.space(6)
  property int contentSpacing: Style.space(7)

  implicitWidth: content.implicitWidth + horizontalPadding * 2
  implicitHeight: content.implicitHeight + verticalPadding * 2
  width: implicitWidth
  height: implicitHeight
  radius: height / 2
  color: Color.popups.background
  borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border,
    Math.max(1, Style.space(2)))

  RowLayout {
    id: content
    anchors.fill: parent
    anchors.leftMargin: root.horizontalPadding
    anchors.rightMargin: root.horizontalPadding
    anchors.topMargin: root.verticalPadding
    anchors.bottomMargin: root.verticalPadding
    spacing: root.contentSpacing
  }
}

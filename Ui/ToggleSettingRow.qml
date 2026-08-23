import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hasCursor: false
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  signal clicked()
  signal hovered(bool on)

  activeFocusOnTab: true
  implicitHeight: Math.max(labels.implicitHeight, toggle.implicitHeight)

  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()

  Accessible.role: Accessible.CheckBox
  Accessible.name: label
  Accessible.checked: checked
  Accessible.onPressAction: clicked()

  Column {
    id: labels
    anchors.left: parent.left
    anchors.right: toggle.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    Text { width: parent.width; text: root.label; color: root.foreground; font.family: root.fontFamily; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
    Text { width: parent.width; text: root.description; color: root.muted; font.family: root.fontFamily; font.pixelSize: Style.font.bodySmall; wrapMode: Text.WordWrap }
  }

  ToggleSwitch {
    id: toggle
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    checked: root.checked
    interactive: false
    cursorRing: true
    hasCursor: root.hasCursor || root.activeFocus
    foreground: root.foreground
    accent: root.accent
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: root.hovered(containsMouse)
    onClicked: root.clicked()
  }
}

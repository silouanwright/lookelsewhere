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
  readonly property real controlX: toggle.x
  readonly property real controlY: toggle.y
  readonly property real controlHeight: toggle.height

  signal clicked()
  signal hovered(bool on)

  function activate() { if (enabled) clicked() }

  activeFocusOnTab: true
  implicitHeight: Math.max(labels.implicitHeight, toggle.implicitHeight)

  Keys.onReturnPressed: root.activate()
  Keys.onEnterPressed: root.activate()
  Keys.onSpacePressed: root.activate()

  Accessible.role: Accessible.CheckBox
  Accessible.name: label
  Accessible.checked: checked
  Accessible.onPressAction: clicked()

  SettingLabels {
    id: labels
    anchors.left: parent.left
    anchors.right: toggle.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    label: root.label
    description: root.description
    foreground: root.foreground
    muted: root.muted
    fontFamily: root.fontFamily
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

import QtQuick
import qs.Commons
import qs.Ui

Button {
  id: root

  property string label: ""
  property int labelWeight: Font.Bold
  property bool actionEnabled: true
  property string disabledTooltipText: ""

  function activate() { if (actionEnabled && enabled) clicked() }

  text: ""
  verticalPadding: Style.space(4)
  radius: Math.min(height / 2, Style.cornerRadius + Style.space(2))
  implicitWidth: labelText.implicitWidth + horizontalPadding * 2 + Math.max(2, Style.normalBorderWidth * 2)
  implicitHeight: labelText.implicitHeight + verticalPadding * 2 + Math.max(2, Style.normalBorderWidth * 2)
  opacity: actionEnabled ? 1 : 0.42

  Behavior on opacity { NumberAnimation { duration: 120 } }

  Text {
    id: labelText
    anchors.centerIn: parent
    text: root.label
    color: root.selected ? Style.selectedStateColor(root.foreground, root.accent) : root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.fontSize
    font.weight: root.labelWeight
    renderType: Text.NativeRendering
    Accessible.ignored: true
  }

  MouseArea {
    id: disabledHover
    anchors.fill: parent
    z: 2
    visible: !root.actionEnabled
    hoverEnabled: true
    cursorShape: Qt.ArrowCursor
  }

  PanelToolTip {
    visible: !root.actionEnabled && root.disabledTooltipText !== ""
      && disabledHover.containsMouse
    text: root.disabledTooltipText
    fontFamily: root.fontFamily
  }
}

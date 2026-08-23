import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Ui

Button {
  id: root

  required property string iconPath
  property string displayIconPath: iconPath
  property color idleForeground: Color.muted

  text: ""
  iconText: ""
  focusable: true
  bordered: false
  horizontalPadding: 0
  verticalPadding: 0
  implicitWidth: iconSize
  implicitHeight: iconSize
  color: "transparent"
  borderSpec: Border.none()

  readonly property color glyphColor: selected
    ? accent
    : (hot || activeFocus ? foreground : idleForeground)

  Shape {
    width: 256
    height: 256
    anchors.centerIn: parent
    scale: root.iconSize / 256
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: root.glyphColor
      PathSvg { path: root.displayIconPath }

      Behavior on fillColor { ColorAnimation { duration: 120 } }
    }
  }
}

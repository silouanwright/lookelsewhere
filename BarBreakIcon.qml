import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property color color: "white"

  implicitWidth: 32
  implicitHeight: 32

  Shape {
    width: 256
    height: 256
    anchors.centerIn: parent
    scale: Math.min(root.width, root.height) / 256
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: root.color
      PathSvg { path: "M216,72H32V48a8,8,0,0,0-16,0V208a8,8,0,0,0,16,0V176H240v32a8,8,0,0,0,16,0V112A40,40,0,0,0,216,72ZM32,88h72v72H32Z" }
    }
  }
}

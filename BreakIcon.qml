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
    // This icon is animated through the overlay's blur/scale layer. Keeping
    // the SVG curves analytic avoids visible tessellation changes in motion.
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeWidth: -1
      fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.2)
      PathSvg { path: "M248,112v56H112V80H216A32,32,0,0,1,248,112Z" }
    }

    ShapePath {
      strokeWidth: -1
      fillColor: root.color
      PathSvg { path: "M216,72H32V48a8,8,0,0,0-16,0V208a8,8,0,0,0,16,0V176H240v32a8,8,0,0,0,16,0V112A40,40,0,0,0,216,72ZM32,88h72v72H32Zm88,72V88h96a24,24,0,0,1,24,24v48Z" }
    }
  }
}

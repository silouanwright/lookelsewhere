pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Ui
import "../vendor/qmlpack/oma-ui-kit/Ui" as LookUi

Row {
  id: root

  property var options: []
  property string value: ""
  property bool hintsVisible: false
  property color foreground: Color.popups.text
  property color background: Color.popups.background
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property int focusedIndex: 0

  signal changed(string value)
  signal downRequested()
  signal upRequested()

  spacing: Style.space(5)
  activeFocusOnTab: true

  function selectedIndex() {
    for (let i = 0; i < options.length; i++)
      if (String(options[i].value) === value) return i
    return 0
  }

  onActiveFocusChanged: if (activeFocus) focusedIndex = selectedIndex()

  Keys.onPressed: function(event) {
    if (event.key === Qt.Key_Left || event.text === "h") {
      focusedIndex = Math.max(0, focusedIndex - 1)
      root.changed(String(options[focusedIndex].value))
      event.accepted = true
    } else if (event.key === Qt.Key_Right || event.text === "l") {
      focusedIndex = Math.min(options.length - 1, focusedIndex + 1)
      root.changed(String(options[focusedIndex].value))
      event.accepted = true
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
      root.changed(String(options[focusedIndex].value))
      event.accepted = true
    } else if (event.key === Qt.Key_Down || event.text === "j") {
      root.downRequested()
      event.accepted = true
    } else if (event.key === Qt.Key_Up || event.text === "k") {
      root.upRequested()
      event.accepted = true
    }
  }

  Repeater {
    model: root.options

    delegate: Item {
      required property var modelData
      required property int index
      implicitWidth: tabButton.implicitWidth
      implicitHeight: tabButton.implicitHeight

      Button {
        id: tabButton
        anchors.fill: parent
        implicitWidth: tabContent.implicitWidth + horizontalPadding * 2
        implicitHeight: Style.space(34)
        selected: String(modelData.value) === root.value
        hasCursor: root.activeFocus && root.focusedIndex === index
        bordered: true
        focusable: false
        foreground: root.foreground
        background: root.background
        accent: root.accent
        fontFamily: root.fontFamily
        horizontalPadding: Style.space(8)
        verticalPadding: Style.space(6)
        Accessible.role: Accessible.PageTab
        Accessible.name: String(modelData.label)
        Accessible.onPressAction: clicked()
        onClicked: root.changed(String(modelData.value))

        Row {
          id: tabContent
          anchors.centerIn: parent
          spacing: Style.space(5)

          Item {
            width: Style.font.icon
            height: width

            Shape {
              width: 256
              height: 256
              anchors.centerIn: parent
              scale: parent.width / 256
              preferredRendererType: Shape.CurveRenderer

              ShapePath {
                strokeWidth: -1
                fillColor: tabButton.selected
                  ? Style.selectedStateColor(root.foreground, root.accent)
                  : root.foreground
                PathSvg { path: String(modelData.iconPath) }

                Behavior on fillColor { ColorAnimation { duration: 120 } }
              }
            }
          }

          Text {
            text: String(modelData.label)
            color: tabButton.selected
              ? Style.selectedStateColor(root.foreground, root.accent)
              : root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            font.weight: tabButton.selected ? Font.DemiBold : Font.Normal
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      LookUi.KeyHintBadge {
        visible: root.hintsVisible
        keyText: String(modelData.key)
        centerOnCorner: true
      }
    }
  }
}

import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root

  property var options: []
  property string value: ""
  property bool hintsVisible: false
  property color foreground: Color.popups.text
  property color background: Color.popups.background
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.bodySmall
  property int focusedIndex: 0

  signal changed(string value)
  signal downRequested()
  signal upRequested()

  spacing: Style.spacing.md
  activeFocusOnTab: true

  function selectedIndex() {
    for (var i = 0; i < options.length; i++)
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
        text: String(modelData.label)
        selected: String(modelData.value) === root.value
        hasCursor: root.activeFocus && root.focusedIndex === index
        bordered: true
        foreground: root.foreground
        background: root.background
        accent: root.accent
        fontFamily: root.fontFamily
        fontSize: root.fontSize
        Accessible.role: Accessible.PageTab
        Accessible.name: text
        Accessible.onPressAction: clicked()
        onClicked: root.changed(String(modelData.value))
      }

      KeyHintBadge {
        visible: root.hintsVisible
        keyText: String(modelData.key)
        centerOnCorner: true
      }
    }
  }
}

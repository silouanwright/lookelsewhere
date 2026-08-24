import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string label: ""
  property string description: ""
  property string value: ""
  property var options: []
  property bool hasCursor: false
  property color foreground: Color.popups.text
  property color muted: Color.muted
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property bool suppressTriggerRelease: false
  readonly property bool popupOpen: field.popupOpen

  signal changed(string value)
  signal hovered(bool on)
  signal popupClosed()

  function activate() { if (enabled) field.toggle() }
  function toggle() { activate() }

  implicitHeight: Math.max(labels.implicitHeight, field.implicitHeight)

  SettingLabels {
    id: labels
    anchors.left: parent.left
    anchors.right: field.left
    anchors.rightMargin: Style.space(12)
    anchors.verticalCenter: parent.verticalCenter
    label: root.label
    description: root.description
    foreground: root.foreground
    muted: root.muted
    fontFamily: root.fontFamily
  }

  SettingDropdown {
    id: field
    width: Style.space(132)
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    showLabel: false
    value: root.value
    options: root.options
    foreground: root.foreground
    accent: root.accent
    fontFamily: root.fontFamily
    hasCursor: root.hasCursor
    onHovered: function(on) { root.hovered(on) }
    onChanged: function(next) { root.changed(next) }
    onPopupOpenChanged: if (!popupOpen) {
      if (triggerGuard.containsMouse) root.suppressTriggerRelease = true
      root.popupClosed()
    }
  }

  MouseArea {
    id: triggerGuard
    x: field.x
    y: field.y
    width: field.width
    height: field.height
    z: 1
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    preventStealing: true
    onPressed: function(mouse) {
      mouse.accepted = true
    }
    onReleased: function(mouse) {
      if (root.suppressTriggerRelease) root.suppressTriggerRelease = false
      else if (field.popupOpen) field.close()
      else field.open()
      mouse.accepted = true
    }
    onCanceled: root.suppressTriggerRelease = false
  }
}

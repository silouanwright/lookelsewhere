import QtQuick

Item {
  id: root

  property bool active: false
  property bool suspended: false
  property bool hintsVisible: false

  readonly property bool acceptingCommands: active && !suspended

  signal hintsToggleRequested(bool visible)

  function toggleHints() {
    hintsToggleRequested(!hintsVisible)
  }

  width: 0
  height: 0
  visible: false
}

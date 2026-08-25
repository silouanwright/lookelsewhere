import QtQuick

Shortcut {
  id: root

  required property CommandLayer commandLayer
  property bool available: true

  signal invoked()

  context: Qt.WindowShortcut
  enabled: commandLayer.acceptingCommands && available
  onActivated: invoked()
}

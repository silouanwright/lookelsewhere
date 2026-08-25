# oma-command-layer

Add configurable, window-scoped command shortcuts and visually positioned key
hints to an Omarchy QML panel.

```bash
qmlpack add oma-command-layer github:silouanwright/omatools/packages/oma-command-layer@0.2.1
```

The package keeps shortcuts local to the focused panel, suspends them while an
embedded control owns input, normalizes user mappings, and recovers duplicate
keys to consumer-defined defaults. Opening another Omarchy panel naturally
deactivates the commands because they use `Qt.WindowShortcut`.

```qml
import "vendor/qmlpack/oma-command-layer/Ui" as OmaCommands

OmaCommands.CommandLayer {
  id: commands
  active: panel.opened
  suspended: dropdown.popupOpen
  hintsVisible: settings.showKeyboardHints

  OmaCommands.WindowCommand {
    id: toggleHints
    commandLayer: commands
    sequence: "?"
    onInvoked: commands.toggleHints()
  }
}

Button {
  id: settingsButton
  text: qsTr("Settings")

  OmaCommands.CommandHint {
    commandLayer: commands
    keyText: "O"
    placeRight: true
    centerOnCorner: true
  }
}
```

Set `suspended` while a dropdown or editor owns the keyboard. The command layer
then ignores jump keys until that control exits. Because commands use
`Qt.WindowShortcut`, opening another Omarchy panel also suspends them naturally.

The consuming plugin owns its actions, default keys, mappings, and persistence.

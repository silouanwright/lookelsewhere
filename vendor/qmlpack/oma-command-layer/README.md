# oma-command-layer

Add configurable, window-scoped command shortcuts and visually positioned key
hints to an Omarchy QML panel.

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
    commandLayer: commands
    sequence: "?"
    onInvoked: commands.toggleHints()
  }
}
```

The consuming plugin owns its actions, default keys, and persistence.

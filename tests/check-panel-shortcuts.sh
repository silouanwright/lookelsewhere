#!/usr/bin/env bash
set -euo pipefail

panel="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Panel.qml}"
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
keyboard_line=$(grep -n -m1 '^  KeyboardPanel {' "$panel" | cut -d: -f1)
first_shortcut_line=$(grep -n -m1 '^[[:space:]]*Shortcut {' "$panel" | cut -d: -f1)
window_shortcuts=$(grep -c 'context: Qt.WindowShortcut' "$panel")

test "$first_shortcut_line" -gt "$keyboard_line"
test "$window_shortcuts" -eq 14
! grep -q 'context: Qt.ApplicationShortcut' "$panel"
! grep -q 'service && !service.interrupting' "$panel"
grep -q 'optionsCursorIndex <= optionsTabStart()' "$panel"
grep -q 'root.setOptionsCursor(root.optionsTabStart())' "$panel"
grep -q 'KeyNavigation.right: statsButton' "$panel"
grep -q 'KeyNavigation.down: root.page === "options" ? settingsTabs' "$panel"
grep -q 'onUpRequested: settingsButton.forceActiveFocus()' "$panel"
grep -q 'focusTarget: root.page === "options" ? settingsTabs : neutralFocus' "$panel"
grep -q 'displayIconPath: root.page === "options"' "$panel"
grep -q 'property bool suppressTriggerRelease: false' "$repo/Ui/DropdownSettingRow.qml"
grep -q 'if (triggerGuard.containsMouse) root.suppressTriggerRelease = true' "$repo/Ui/DropdownSettingRow.qml"
grep -q 'event.key === Qt.Key_Space' "$repo/Ui/SettingDropdown.qml"
grep -q 'onClicked: root.clicked()' "$repo/Ui/ToggleSettingRow.qml"
grep -q 'persistSettings({ showKeyboardHints: !keyboardHintsVisible })' "$panel"

echo "Panel shortcuts and spatial keyboard navigation are wired to KeyboardPanel."

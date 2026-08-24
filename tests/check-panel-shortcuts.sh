#!/usr/bin/env bash
set -euo pipefail

panel="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Panel.qml}"
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
settings_page="$repo/SettingsPage.qml"
now_view="$repo/PanelNowView.qml"
keyboard_line=$(grep -n -m1 '^  KeyboardPanel {' "$panel" | cut -d: -f1)
first_shortcut_line=$(grep -n -m1 '^[[:space:]]*Shortcut {' "$panel" | cut -d: -f1)
window_shortcuts=$(grep -c 'context: Qt.WindowShortcut' "$panel")

test "$first_shortcut_line" -gt "$keyboard_line"
test "$window_shortcuts" -eq 14
! grep -q 'context: Qt.ApplicationShortcut' "$panel"
! grep -q 'service && !service.interrupting' "$panel"
grep -q 'function targets()' "$settings_page"
grep -q 'target && typeof target.activate === "function"' "$settings_page"
! grep -q 'optionsTabStart\|optionsTabEnd\|switch (.*cursorIndex)' "$settings_page"
grep -q 'function activate()' "$repo/Ui/ToggleSettingRow.qml"
grep -q 'function activate()' "$repo/Ui/DropdownSettingRow.qml"
grep -q 'function activate()' "$repo/Ui/NumberSettingRow.qml"
grep -q 'KeyNavigation.right: statsButton' "$panel"
grep -q 'KeyNavigation.down: root.page === "options" ? settingsPage.initialFocusTarget' "$panel"
grep -q 'onUpRequested: settingsPage.settingsButtonTarget.forceActiveFocus()' "$settings_page"
grep -q 'focusTarget: root.page === "options" ? settingsPage.initialFocusTarget : neutralFocus' "$panel"
grep -q 'displayIconPath: root.page === "options"' "$panel"
grep -q 'property bool suppressTriggerRelease: false' "$repo/Ui/DropdownSettingRow.qml"
grep -q 'if (triggerGuard.containsMouse) root.suppressTriggerRelease = true' "$repo/Ui/DropdownSettingRow.qml"
grep -q 'event.key === Qt.Key_Space' "$repo/Ui/SettingDropdown.qml"
grep -q 'onClicked: root.clicked()' "$repo/Ui/ToggleSettingRow.qml"
grep -q 'persistSettings({ showKeyboardHints: !keyboardHintsVisible })' "$panel"
grep -q 'PanelNowView {' "$panel"
grep -q 'KeyNavigation.tab: root.delayActionsEnabled ? postpone1Button : root.shortcutsTarget' "$now_view"
grep -q 'KeyNavigation.right: root.settingsTarget' "$now_view"

echo "Panel shortcuts and spatial keyboard navigation are wired to KeyboardPanel."

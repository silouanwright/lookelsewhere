#!/usr/bin/env bash
set -euo pipefail

panel="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/Views/Panel.qml}"
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
settings_page="$repo/Views/SettingsPage.qml"
now_view="$repo/Views/PanelNowView.qml"
ui="$repo/vendor/qmlpack/oma-ui-kit/Ui"
keyboard_line=$(grep -n -m1 '^  KeyboardPanel {' "$panel" | cut -d: -f1)
first_shortcut_line=$(grep -n -m1 'OmaCommands.WindowCommand {' "$panel" | cut -d: -f1)
window_shortcuts=$(grep -c 'OmaCommands.WindowCommand {' "$panel")

test "$first_shortcut_line" -gt "$keyboard_line"
test "$window_shortcuts" -eq 14
! grep -q 'context: Qt.ApplicationShortcut' "$panel"
grep -q 'suspended: root.numberEditorActive || root.dropdownOpen' "$panel"
grep -q 'context: Qt.WindowShortcut' "$repo/vendor/qmlpack/oma-command-layer/Ui/WindowCommand.qml"
grep -q 'visible: commandLayer.hintsVisible' "$repo/vendor/qmlpack/oma-command-layer/Ui/CommandHint.qml"
! grep -q 'service && !service.interrupting' "$panel"
grep -q 'function targets()' "$settings_page"
grep -q 'target && typeof target.activate === "function"' "$settings_page"
! grep -q 'optionsTabStart\|optionsTabEnd\|switch (.*cursorIndex)' "$settings_page"
grep -q 'function activate()' "$ui/ToggleSettingRow.qml"
grep -q 'function activate()' "$ui/DropdownSettingRow.qml"
grep -q 'function activate()' "$ui/NumberSettingRow.qml"
grep -q 'KeyNavigation.right: statsButton' "$panel"
grep -q 'KeyNavigation.down: root.page === "options" ? settingsPage.initialFocusTarget' "$panel"
grep -q 'onUpRequested: settingsPage.settingsButtonTarget.forceActiveFocus()' "$settings_page"
grep -q 'focusTarget: root.page === "options" ? settingsPage.initialFocusTarget : neutralFocus' "$panel"
grep -q 'displayIconPath: root.page === "options"' "$panel"
grep -q 'property bool suppressTriggerRelease: false' "$ui/DropdownSettingRow.qml"
grep -q 'if (triggerGuard.containsMouse) root.suppressTriggerRelease = true' "$ui/DropdownSettingRow.qml"
grep -q 'event.key === Qt.Key_Space' "$ui/SettingDropdown.qml"
grep -q 'onClicked: root.clicked()' "$ui/ToggleSettingRow.qml"
grep -q 'persistSettings({ showKeyboardHints: !keyboardHintsVisible })' "$panel"
grep -q 'experience: \[reduceMotionRow, panelPatternDropdown, soundRow, soundVolumeField,' "$settings_page"
grep -q 'Keys.onTabPressed:' "$settings_page"
grep -q 'if (focusProxy) focusProxy.forceActiveFocus()' "$settings_page"
grep -q 'function hasCursorFor(target)' "$settings_page"
grep -q 'function setCursorTarget(target)' "$settings_page"
! grep -q 'hasCursor: settingsPage.cursorActive && settingsPage.cursorIndex ===' "$settings_page"
! grep -Eq 'onHovered:.*settingsPage\.setCursor\([0-9]+\)' "$settings_page"
grep -q 'PanelNowView {' "$panel"
grep -q 'manuallyPaused: root.manuallyPaused' "$panel"
grep -q 'checked: !!settingsPage.service && !settingsPage.manuallyPaused' "$settings_page"
grep -q 'text: root.manuallyPaused ? qsTr("Breaks paused")' "$now_view"
grep -q 'KeyNavigation.tab: root.delayActionsEnabled ? postpone1Button : root.shortcutsTarget' "$now_view"
grep -q 'KeyNavigation.right: root.settingsTarget' "$now_view"

echo "Panel shortcuts and spatial keyboard navigation are wired to KeyboardPanel."

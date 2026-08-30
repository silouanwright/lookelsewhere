#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

grep -q 'Accessible.role: Accessible.ComboBox' "$repo/vendor/qmlpack/oma-ui-kit/Ui/SettingDropdown.qml"
grep -q 'Accessible.selected: index === optionList.currentIndex' "$repo/vendor/qmlpack/oma-ui-kit/Ui/SettingDropdown.qml"
grep -q 'Accessible.onPressAction: activate()' "$repo/vendor/qmlpack/oma-ui-kit/Ui/WeightedButton.qml"
grep -q 'Accessible.role: root.actionEnabled && root.enabled ? Accessible.Button : Accessible.StaticText' "$repo/vendor/qmlpack/oma-ui-kit/Ui/WeightedButton.qml"
grep -q 'onClosed: if (root.visible && trigger.visible)' "$repo/vendor/qmlpack/oma-ui-kit/Ui/SettingDropdown.qml"
grep -q 'Accessible.role: Accessible.PageTabList' "$repo/Ui/SettingsCategoryBar.qml"
grep -q 'Accessible.name: settingsPage.cursorAccessibleName' "$repo/Views/Panel.qml"
grep -q 'Accessible.name: qsTr("%1, %2, ended %3")' "$repo/Views/StatsView.qml"
grep -q 'Accessible.checked: selected' "$repo/Views/PlannedBreaksPage.qml"
grep -q 'Accessible.announce' "$repo/Overlay.qml"
grep -q 'WlrKeyboardFocus.OnDemand' "$repo/Overlay.qml"
grep -q 'maximumLineCount: 3' "$repo/Views/BreakContent.qml"
! grep -q 'scale: fitScale' "$repo/Views/PanelNowView.qml"
! grep -q 'scale: Math.min(1, Math.max(0.1' "$repo/Overlay.qml"
grep -q 'id: breakViewport' "$repo/Overlay.qml"
grep -q 'warningBreakNowButton.forceActiveFocus' "$repo/Overlay.qml"
grep -q 'undoNaturalBreakButton.forceActiveFocus' "$repo/Overlay.qml"
grep -q 'textFormat: Text.PlainText' "$repo/Ui/RollingDigit.qml"
grep -q 'reducedTransparency' "$repo/manifest.json"

echo "Accessibility semantics, focus policy, native sizing, and preferences are wired."

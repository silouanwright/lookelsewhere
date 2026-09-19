#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

# `! grep -q PATTERN file` cannot fail: bash exempts negated commands from
# `set -e`, so a "must not contain" guard written that way asserts nothing.
# Every absence assertion goes through this helper so it can actually fail.
assert_absent() {
  local pattern=$1 file=$2
  if grep -q -- "$pattern" "$file"; then
    echo "FAIL: $file must not contain '$pattern'" >&2
    return 1
  fi
}

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
grep -q 'maximumLineCount: 3' "$repo/Views/BreakContent.qml"
grep -q 'id: breakViewport' "$repo/Overlay.qml"
grep -q 'textFormat: Text.PlainText' "$repo/Ui/RollingDigit.qml"
grep -q 'reducedTransparency' "$repo/manifest.json"

# Overlay keyboard policy. Warning cards, the final chip, and the natural-break
# notice are informational surfaces: they must never request keyboard focus or
# move it onto a control, or an Enter typed in the user's own application
# activates the focused "Break now"/"Start break"/"Undo" button and the break
# starts unasked. Only a running break may own the keyboard.
grep -q 'WlrKeyboardFocus.Exclusive' "$repo/Overlay.qml"
grep -q 'WlrKeyboardFocus.None' "$repo/Overlay.qml"
assert_absent 'WlrKeyboardFocus.OnDemand' "$repo/Overlay.qml"
assert_absent 'forceActiveFocus' "$repo/Overlay.qml"
# Removing focus stealing must not remove the assistive-technology activation
# path that replaced it.
grep -q 'Accessible.onPressAction' "$repo/Overlay.qml"
assert_absent 'scale: fitScale' "$repo/Views/PanelNowView.qml"
assert_absent 'scale: Math.min(1, Math.max(0.1' "$repo/Overlay.qml"

echo "Accessibility semantics, focus policy, native sizing, and preferences are wired."

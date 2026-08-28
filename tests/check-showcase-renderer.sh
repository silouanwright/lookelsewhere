#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
grep -q 'Qt.resolvedUrl("../assets/"' "$repo/Ui/PanelPattern.qml"
output=$(mktemp /tmp/lookelsewhere-showcase-test.XXXXXX.png)
pattern_output=$(mktemp /tmp/lookelsewhere-showcase-pattern-test.XXXXXX.png)
trap 'find "$output" "$pattern_output" -delete 2>/dev/null || true' EXIT

theme_before=$(readlink -f "$HOME/.local/state/omarchy/current/theme")
"$repo/tools/render-showcase" --surface panel --density 1 --output "$output" tokyo-night >/dev/null
"$repo/tools/render-showcase" --surface panel --density 1 --pattern graph-paper --output "$pattern_output" tokyo-night >/dev/null
theme_after=$(readlink -f "$HOME/.local/state/omarchy/current/theme")

test "$theme_before" = "$theme_after"
test "$(identify -format '%w' "$output")" -gt 200
test "$(identify -format '%h' "$output")" -gt 150
difference=$(compare -metric AE "$output" "$pattern_output" null: 2>&1 || true)
awk '{ exit !($1 > 0) }' <<<"$difference"
grep -q 'PanelNowView {' "$repo/Views/Panel.qml"
grep -q 'BreakContent {' "$repo/Overlay.qml"
grep -q 'PanelPattern {' "$repo/Views/Panel.qml"
grep -q 'vendor/qmlpack/oma-showcase/bin/oma-showcase' "$repo/tools/render-showcase"

echo "Showcase rendering is offscreen, themed, and shared with production views."

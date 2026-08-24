#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$(mktemp /tmp/lookelsewhere-showcase-test.XXXXXX.png)
trap 'find "$output" -delete 2>/dev/null || true' EXIT

theme_before=$(readlink -f "$HOME/.local/state/omarchy/current/theme")
"$repo/tools/render-showcase" --surface panel --density 1 --output "$output" tokyo-night >/dev/null
theme_after=$(readlink -f "$HOME/.local/state/omarchy/current/theme")

test "$theme_before" = "$theme_after"
test "$(identify -format '%w' "$output")" -gt 200
test "$(identify -format '%h' "$output")" -gt 150
grep -q 'PanelNowView {' "$repo/Panel.qml"
grep -q 'BreakContent {' "$repo/Overlay.qml"

echo "Showcase rendering is offscreen, themed, and shared with production views."

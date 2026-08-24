#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
service="$repo/Service.qml"

grep -q 'stateReadLimit: 64 \* 1024' "$service"
grep -q 'head", "-c", String(service.stateReadLimit + 1)' "$service"
grep -q 'data.length > service.stateReadLimit' "$service"
grep -q 'blockAllReads: true' "$service"
grep -q 'hyprctl activewindow -j | head -c 65537' "$service"
grep -q '\.\[0:256\]' "$service"

echo "State and active-window inputs are bounded before QML parsing."

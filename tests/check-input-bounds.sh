#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
service="$repo/Service.qml"

grep -q 'stateReadLimit: 64 \* 1024' "$service"
grep -q 'command: \[service.stateReaderPath, service.statePath\]' "$service"
grep -q 'os.O_NOFOLLOW | os.O_NONBLOCK' "$repo/tools/read-state"
grep -q 'stat.S_ISREG(metadata.st_mode)' "$repo/tools/read-state"
grep -q 'blockAllReads: true' "$service"
grep -q 'hyprctl activewindow -j | head -c 65537' "$service"
grep -q '\.\[0:256\]' "$service"

echo "State and active-window inputs are bounded before QML parsing."

#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
service="$repo/Service.qml"

grep -q 'stateReadLimit: 64 \* 1024' "$service"
grep -q 'command: \[service.boundedReaderPath, "--max-bytes"' "$service"
grep -q 'os.O_NOFOLLOW | os.O_NONBLOCK' "$repo/tools/bounded-read"
grep -q 'dir_fd=directory_fd' "$repo/tools/bounded-read"
grep -q 'stat.S_ISREG(metadata.st_mode)' "$repo/tools/bounded-read"
grep -q 'interval: 5000' "$service"
grep -q 'exec install -d -m 700' "$service"
grep -q 'blockAllReads: true' "$service"
grep -q 'hyprctl activewindow -j | head -c 65537' "$service"
grep -q '\.\[0:256\]' "$service"

echo "State and active-window inputs are bounded before QML parsing."

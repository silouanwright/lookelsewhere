#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
service="$repo/Service.qml"

grep -q 'stateReadLimit: 64 \* 1024' "$service"
grep -q 'command: \[service.boundedReaderPath, "--max-bytes"' "$service"
reader="$repo/vendor/qmlpack/bounded-read/bin/bounded-read"
grep -q 'os.O_NOFOLLOW | os.O_NONBLOCK' "$reader"
grep -q 'dir_fd=directory_fd' "$reader"
grep -q 'stat.S_ISREG(metadata.st_mode)' "$reader"
grep -q 'interval: 5000' "$service"
grep -q 'exec install -d -m 700' "$service"
grep -q 'blockAllReads: true' "$service"
grep -q 'hyprctl activewindow -j | head -c 65537' "$service"
grep -q '\.\[0:256\]' "$service"
pipewire_helper="$repo/tools/pipewire-evidence"
grep -q 'MAX_NODE_BYTES = 64 \* 1024' "$pipewire_helper"
grep -q 'TIMEOUT_SECONDS = 0.75' "$pipewire_helper"
grep -q 'application.process.binary' "$pipewire_helper"
! grep -q 'node\.properties' "$service"
grep -q 'pipewireEvidencePath' "$service"
grep -q 'objects: service.pipewireLinkGroups' "$service"
grep -q '!nodes\[j\]\.isStream' "$service"
grep -q 'var didTimeOut = timedOut' "$service"
grep -q 'if (retryCount < 1)' "$service"

echo "State, active-window, and PipeWire inputs are bounded and shaped before QML parsing."

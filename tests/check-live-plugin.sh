#!/usr/bin/env bash
set -euo pipefail

shell=(quickshell ipc -n -p /usr/share/omarchy/shell)
"${shell[@]}" call look-elsewhere-panel open
"${shell[@]}" show | grep -q '^target look-elsewhere-panel$'

if quickshell log -n -p /usr/share/omarchy/shell --no-color 2>&1 \
    | grep -E 'look-elsewhere/.*(Type .* unavailable|is not a type)'; then
  echo "LookElsewhere has QML type-loading errors." >&2
  exit 1
fi

echo "LookElsewhere loads and opens in the running Omarchy Shell."

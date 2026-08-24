#!/usr/bin/env bash
set -euo pipefail

shell=(quickshell ipc -n -p /usr/share/omarchy/shell)
plugin="${LOOKELSEWHERE_PLUGIN_DIR:-$HOME/.config/omarchy/plugins/io.github.silouanwright.look-elsewhere}"
"${shell[@]}" call look-elsewhere-panel open
"${shell[@]}" show | grep -q '^target look-elsewhere-panel$'

if quickshell log -n -p /usr/share/omarchy/shell --no-color 2>&1 \
    | grep -E 'look-elsewhere/.*(Type .* unavailable|is not a type)'; then
  echo "LookElsewhere has QML type-loading errors." >&2
  exit 1
fi

grep -q 'stateReaderPath' "$plugin/Service.qml"
grep -q 'os.O_NOFOLLOW | os.O_NONBLOCK' "$plugin/tools/read-state"
grep -q 'blockAllReads: true' "$plugin/Service.qml"

echo "LookElsewhere loads and opens in the running Omarchy Shell."

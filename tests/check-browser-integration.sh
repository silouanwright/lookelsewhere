#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
host="$root/browser-extension/native-host/lookelsewhere-browser-host"

python3 "$host" --self-test
node "$root/browser-extension/check.js"
jq -e '
  .manifest_version == 3
  and .permissions == ["nativeMessaging"]
  and (.host_permissions | sort) == ["http://*/*", "https://*/*"]
' "$root/browser-extension/chromium/manifest.json" >/dev/null
grep -q 'chrome-extension://icmgnmabpjbgfogamiaaadaolhopdhmp/' \
  "$root/browser-extension/native-host/io.github.silouanwright.look_elsewhere.json.in"
grep -q 'browserContextEvidence' "$root/Service.qml"

echo "Browser integration is bounded, privacy-minimized, and model-tested."

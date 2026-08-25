#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
helper="$repo/tools/pipewire-evidence"
fixture=$(mktemp -d /tmp/lookelsewhere-pipewire-evidence.XXXXXX)
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/bin"

cat > "$fixture/bin/pw-dump" <<'SCRIPT'
#!/usr/bin/env bash
case "${2:-}" in
  7) printf '%s\n' '[{"id":7,"type":"PipeWire:Interface:Node","info":{"props":{"media.class":"Stream/Input/Audio","media.category":"Capture","media.role":"Communication","application.name":"Call app","media.title":"private title"}}}]' ;;
  8) printf '%s\n' '[{"id":8,"type":"PipeWire:Interface:Node","info":{"props":{"media.class":"Stream/Output/Audio","media.role":"Music","application.name":"Player"}}}]' ;;
  *) printf '%s\n' '[]' ;;
esac
SCRIPT
chmod +x "$fixture/bin/pw-dump"

sed "s#/usr/bin/pw-dump#$fixture/bin/pw-dump#" "$helper" > "$fixture/helper"
chmod +x "$fixture/helper"
output=$("$fixture/helper" 7 8)
jq -e 'length == 2 and .[0].role == "communication" and .[0].captureAudio == true and .[0].applications == ["Call app"] and .[1].role == "" and .[1].captureAudio == false' <<<"$output" >/dev/null
! grep -q 'private title' <<<"$output"
if "$fixture/helper" nope >/dev/null 2>&1; then exit 1; fi

cat > "$fixture/bin/pw-dump" <<'SCRIPT'
#!/usr/bin/env bash
sleep 5
SCRIPT
chmod +x "$fixture/bin/pw-dump"
start=$SECONDS
if "$fixture/helper" 7 8 >/dev/null 2>&1; then exit 1; fi
test "$((SECONDS - start))" -lt 3

echo "PipeWire evidence is byte/time-bounded and reduced to coarse role, capture, and application fields."

#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
reader="$repo/tools/bounded-read"
fixture=$(mktemp -d /tmp/lookelsewhere-bounded-read.XXXXXX)
trap 'find "$fixture" -depth -delete 2>/dev/null || true' EXIT

printf '{"version":1}\n' > "$fixture/state.json"
test "$($reader --max-bytes 65536 "$fixture/state.json")" = '{"version":1}'

head -c 65537 /dev/zero > "$fixture/large.json"
if "$reader" --max-bytes 65536 "$fixture/large.json" > "$fixture/large.out"; then exit 1; fi
test ! -s "$fixture/large.out"

ln -s state.json "$fixture/link.json"
if "$reader" --max-bytes 65536 "$fixture/link.json" > "$fixture/link.out"; then exit 1; fi
test ! -s "$fixture/link.out"

mkfifo "$fixture/state.fifo"
if timeout 2 "$reader" --max-bytes 65536 "$fixture/state.fifo" > "$fixture/fifo.out"; then exit 1; fi
test ! -s "$fixture/fifo.out"

grep -q 'metadata.st_uid != os.getuid()' "$reader"
if "$reader" --max-bytes 0 "$fixture/state.json" > "$fixture/invalid.out"; then exit 1; fi
echo "Bounded reads reject invalid limits, oversized, linked, non-regular, and foreign-owned files."

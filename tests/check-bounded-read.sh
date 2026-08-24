#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
reader="$repo/vendor/qmlpack/bounded-read/bin/bounded-read"
fixture=$(mktemp -d /tmp/lookelsewhere-bounded-read.XXXXXX)
trap 'find "$fixture" -depth -delete 2>/dev/null || true' EXIT

test "$(head -n 1 "$reader")" = '#!/usr/bin/python3'

printf '{"version":1}\n' > "$fixture/state.json"
test "$($reader --max-bytes 65536 "$fixture/state.json")" = '{"version":1}'

head -c 65536 /dev/zero > "$fixture/exact.json"
"$reader" --max-bytes 65536 "$fixture/exact.json" > "$fixture/exact.out"
test "$(stat -c %s "$fixture/exact.out")" = 65536

head -c 65537 /dev/zero > "$fixture/large.json"
if "$reader" --max-bytes 65536 "$fixture/large.json" > "$fixture/large.out"; then exit 1; fi
test ! -s "$fixture/large.out"

ln -s state.json "$fixture/link.json"
if "$reader" --max-bytes 65536 "$fixture/link.json" > "$fixture/link.out"; then exit 1; fi
test ! -s "$fixture/link.out"

mkdir "$fixture/real-parent"
printf '{"parent":"safe"}\n' > "$fixture/real-parent/state.json"
ln -s real-parent "$fixture/linked-parent"
if "$reader" --max-bytes 65536 "$fixture/linked-parent/state.json" > "$fixture/parent-link.out"; then exit 1; fi
test ! -s "$fixture/parent-link.out"

mkfifo "$fixture/state.fifo"
if timeout 2 "$reader" --max-bytes 65536 "$fixture/state.fifo" > "$fixture/fifo.out"; then exit 1; fi
test ! -s "$fixture/fifo.out"

grep -q 'metadata.st_uid != os.getuid()' "$reader"
if "$reader" --max-bytes 0 "$fixture/state.json" > "$fixture/invalid.out"; then exit 1; fi
if (cd "$fixture" && "$reader" --max-bytes 65536 state.json > relative.out); then exit 1; fi
echo "Bounded reads reject invalid limits, oversized, linked-path, non-regular, foreign-owned, and relative files."

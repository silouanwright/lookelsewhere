#!/usr/bin/env bash
set -euo pipefail

shell=(quickshell ipc -n -p /usr/share/omarchy/shell)
plugin="${LOOKELSEWHERE_PLUGIN_DIR:-$HOME/.config/omarchy/plugins/io.github.silouanwright.look-elsewhere}"
call() { "${shell[@]}" call look-elsewhere "$@"; }
status() { call status; }

grep -q 'demoNaturalPause = false' "$plugin/Service.qml"

original_config=$(call configuration)
trap 'call demoOff >/dev/null 2>&1 || true' EXIT

check_fixture() {
  local fixture=$1 expected_label=$2
  call demo "$fixture" >/dev/null
  sleep 1.1
  local current
  current=$(status)
  jq -e --arg label "$expected_label" '
    .demo == true and .state == "protected-context" and .contextLabel == $label
  ' <<<"$current" >/dev/null
}

check_fixture meeting Meeting
check_fixture microphone Mic
check_fixture camera Camera
check_fixture screen-sharing Sharing
check_fixture video Video
check_fixture media Media
check_fixture fullscreen Fullscreen
check_fixture dictation Dictation

call demo game >/dev/null
game_before=$(status)
sleep 2
game_after=$(status)
jq -e '.demo == true and .state == "working" and .steamPaused == true
  and .contextLabel == "Game"' <<<"$game_after" >/dev/null
test "$(jq -r '.remainingMs' <<<"$game_before")" = "$(jq -r '.remainingMs' <<<"$game_after")"

call demo flow >/dev/null
states=""
for _ in $(seq 1 22); do
  current=$(status)
  state=$(jq -r .state <<<"$current")
  case " $states " in *" $state "*) ;; *) states="$states $state" ;; esac
  if [[ " $states " == *" warning "* && " $states " == *" final-countdown "* \
    && " $states " == *" breaking "* && " $states " == *" working "* ]]; then
    break
  fi
  sleep 1
done
for required in warning final-countdown breaking working; do
  case " $states " in
    *" $required "*) ;;
    *) echo "Timer flow missed $required; observed:$states" >&2; exit 1 ;;
  esac
done

call demoOff >/dev/null
jq -e '.demo == false' <<<"$(status)" >/dev/null
test "$(call configuration)" = "$original_config"

diagnostics=$(call diagnostics)
jq -e '
  .persistenceBlocked == false
  and .schedulerLastGapMs >= 0
  and .schedulerMaximumGapMs >= .schedulerLastGapMs
  and .schedulerMaximumDurationMs >= .schedulerLastDurationMs
' <<<"$diagnostics" >/dev/null

echo "Protected-context fixtures, Steam pause, authoritative timer flow, and exact configuration restoration passed."

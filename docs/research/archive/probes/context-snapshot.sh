#!/usr/bin/env bash
set -u

# Read-only diagnostic snapshot. It intentionally omits window titles,
# media metadata, URLs, and raw audio/video content.

active_window='{}'
monitors='[]'
mpris='[]'
pipewire_roles='[]'

if command -v hyprctl >/dev/null 2>&1; then
  active_window=$(hyprctl -j activewindow 2>/dev/null | jq '{class, initialClass, fullscreen, fullscreenClient}' 2>/dev/null || printf '{}')
  monitors=$(hyprctl -j monitors 2>/dev/null | jq 'map({name, id, focused})' 2>/dev/null || printf '[]')
fi

if command -v busctl >/dev/null 2>&1; then
  mpris=$(busctl --user list --no-legend 2>/dev/null |
    awk '$1 ~ /^org\.mpris\.MediaPlayer2\./ {print $1}' |
    while IFS= read -r service; do
      status=$(busctl --user get-property "$service" /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player PlaybackStatus 2>/dev/null |
        sed -n 's/^s "\(.*\)"$/\1/p')
      jq -cn --arg service "$service" --arg status "${status:-Unknown}" '{service:$service,status:$status}'
    done | jq -s '.')
fi

if command -v pw-dump >/dev/null 2>&1; then
  pipewire_roles=$(pw-dump 2>/dev/null | jq '[.[] |
    select(.type == "PipeWire:Interface:Node") |
    .info.props as $p |
    select(($p["media.role"] // "") != "") |
    {
      role: $p["media.role"],
      class: ($p["media.class"] // null),
      app: ($p["application.name"] // $p["application.process.binary"] // null),
      state: (.info.state // null)
    }]' 2>/dev/null || printf '[]')
fi

jq -n \
  --argjson active_window "$active_window" \
  --argjson monitors "$monitors" \
  --argjson mpris "$mpris" \
  --argjson pipewire_roles "$pipewire_roles" \
  '{active_window:$active_window,monitors:$monitors,mpris:$mpris,pipewire_roles:$pipewire_roles}'

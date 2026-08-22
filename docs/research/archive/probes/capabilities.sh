#!/usr/bin/env bash
set -u

has() {
  if command -v "$1" >/dev/null 2>&1; then
    printf '%-28s %s\n' "$1" yes
  else
    printf '%-28s %s\n' "$1" no
  fi
}

printf '%-28s %s\n' capability available
has hyprctl
has jq
has busctl
has wpctl
has pw-dump
has wayland-info
has loginctl

if command -v hyprctl >/dev/null 2>&1; then
  printf '\nHyprland:\n'
  hyprctl version 2>/dev/null | sed -n '1p'
  printf 'event socket: '
  socket_path="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-missing}/.socket2.sock"
  if [[ -S $socket_path ]]; then printf 'yes\n'; else printf 'no\n'; fi
fi

if command -v wayland-info >/dev/null 2>&1; then
  printf '\nRelevant advertised Wayland interfaces:\n'
  wayland-info 2>/dev/null |
    sed -n 's/^interface: '\''\([^'\'']*\)'\'', version: [0-9][0-9]*/\1/p' |
    grep -E 'idle|layer|inhibit|session.lock|toplevel' |
    sort -u
fi

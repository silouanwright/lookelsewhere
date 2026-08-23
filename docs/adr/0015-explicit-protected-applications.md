# ADR 0015: Protect Explicitly Configured Applications

- Status: Accepted
- Date: 2026-08-22

## Context

Fullscreen, playback, and microphone signals cannot reliably identify every
game or deep-focus application. Hyprland does provide a coarse focused
application ID, including the `steam_app_<id>` convention used by Steam games.
Window titles are mutable and may contain private content, so they are not an
acceptable policy input.

## Decision

Add a manifest-backed, comma-separated `protectedApps` setting. A configured
application emits high-confidence protected-context evidence only while it is
focused. `steam` is the default and covers both the Steam client and
`steam_app_<numeric-id>` game windows.

Use Quickshell's Wayland app ID when available. For XWayland windows, reconcile
`hyprctl activewindow -j` once per focus change rather than polling. Retain only
the application class and fullscreen boolean; never retain the title.

## Consequences

- Steam games defer a due break up to the existing maximum-delay bound.
- Users can add or remove application IDs without code changes.
- The bar reports the coarse status `Focus`, not the application name.
- Application classification remains explicit user policy rather than an
  expanding built-in database.


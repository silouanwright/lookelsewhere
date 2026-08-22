# Context Detection Feasibility

## Architectural conclusion

Do not put all smart detection into Hyprland and do not require application plugins.

Use a layered evidence model:

1. **Standard desktop evidence** — Wayland idle notifications, MPRIS, PipeWire, D-Bus inhibitors, login/session state.
2. **Hyprland adapter** — active application, fullscreen state, workspace/monitor changes, lock state, special rules.
3. **Optional application adapters** — browser extension, conferencing integrations, editor/dictation integrations.
4. **User policy** — “always suppress for this app,” “never suppress for music,” and temporary modes.

Hyprland should only gain upstream functionality if a generally useful compositor fact is genuinely missing. It should not learn application semantics such as whether Chromium is playing a meeting or a podcast.

## Evidence model

Each sensor emits evidence with a timestamp, confidence, reason, and expiry:

```text
Evidence {
  kind: fullscreen | media_playing | microphone_capture | camera_capture |
        screen_share | idle_inhibited | user_idle | locked | app_rule
  source: hyprland | mpris | pipewire | dbus | portal_adapter | browser_extension | user
  confidence: 0.0..1.0
  observed_at: monotonic timestamp
  expires_at: monotonic timestamp or event-driven removal
  metadata: minimal identifiers only
}
```

The policy engine converts evidence into one of four decisions:

- `allow` — show the break normally
- `soft_delay` — wait for a natural pause up to a deadline
- `suppress_until_clear` — do not display while the condition remains
- `ask` — show a small non-disruptive prompt because confidence is ambiguous

Every decision exposes a reason such as “Paused while microphone capture and a Communication stream are active.”

## Detection paths

| Context | Primary signal | Confidence | Limitations | MVP? |
|---|---|---:|---|---:|
| User actively working | `ext-idle-notify-v1` resumed/idle events | High | Measures input, not cognitive attention | Yes |
| User stepped away | Idle duration exceeding threshold | High | Media apps can generate/inhibit activity | Yes |
| Session locked | login1/session lock signal and Hyprland/Omarchy integration | High | Verify signal ordering | Yes |
| Suspend/resume | login1 `PrepareForSleep` | High | Clock jumps require monotonic time | Yes |
| Fullscreen app | Hyprland socket events plus state reconciliation | High | Fullscreen is not synonymous with video | Yes |
| Active application | Hyprland active-window address/class | High | Window title is privacy-sensitive and mutable | Yes, class only |
| Media playing | MPRIS `PlaybackStatus=Playing` | Medium-high | Browsers may aggregate tabs; music should not always suppress | Yes |
| Audio playback | Active PipeWire output stream | Medium | Music, alerts, games, and calls look similar | Later/MVP probe |
| Microphone/dictation | Active PipeWire input stream | Medium | Cannot distinguish dictation, recording, and meetings alone | Later |
| Meeting/call | Microphone capture + `media.role=Communication` + known app | High when combined | Applications may omit or mislabel roles | Later |
| Camera use | Active PipeWire video capture link/node | Medium-high | V4L2/direct-access and permissions vary | Later |
| Screen sharing | PipeWire node with `media.role=Screen`, portal/backend evidence | Medium | No universal observer API for sessions owned by other apps | Later/adapters |
| Browser video | MPRIS playing + browser active/fullscreen + optional extension | Medium without extension, high with | Background music and inactive tabs | MVP heuristic, extension later |
| Presentation | Fullscreen + idle inhibitor + app rule | Medium-high | Fullscreen editors/games can match | MVP heuristic |
| Game | Fullscreen + Steam/game class + GameMode/inhibitor | Medium-high | Window-class database requires maintenance | Later |
| Screen recording | OBS/recorder class + PipeWire screen stream | Medium-high | Recorder names and portals differ | Later |

## Important technical findings

### MPRIS is the right first media signal

MPRIS exposes a standard `PlaybackStatus` property and emits property-change signals. It is cheaper and semantically clearer than treating any audio stream as video. It still cannot reliably distinguish music from a video, so suppression should depend on user policy, active app, fullscreen state, or an optional browser adapter.

Specification: https://specifications.freedesktop.org/mpris/latest/Player_Interface.html

### PipeWire provides useful metadata, not certainty

PipeWire nodes may identify roles including `Movie`, `Music`, `Camera`, `Screen`, `Communication`, and `Game`. Capture/playback links and node activity can provide strong supporting evidence. Applications do not always label streams correctly, and sandbox visibility must be tested.

Properties: https://pipewire.pages.freedesktop.org/pipewire/page_man_pipewire-props_7.html

### XDG portals do not provide a global meeting registry

The ScreenCast portal manages sessions created by its caller. Its API does not promise a global list of screen-sharing sessions belonging to other applications. A desktop service may infer activity from PipeWire or cooperate with portal backends, but that is an integration project rather than a portable baseline.

Portal API: https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html

### Hyprland is valuable but should remain semantic-neutral

Hyprland’s event socket provides active-window, fullscreen, monitor, workspace, lock-related, and screencast state events. The adapter must periodically reconcile against `hyprctl -j` because event streams can be missed across reconnects and some events are not guaranteed to arrive as neat pairs.

IPC: https://wiki.hypr.land/IPC/

### Layer-shell can focus an overlay but not guarantee confinement

An overlay can request exclusive keyboard focus. The compositor ultimately controls input, and global bindings or session actions may remain available. The strongest honest enforcement is invoking the session lock screen.

Protocol: https://wayland.app/protocols/wlr-layer-shell-unstable-v1

## Do we need Hyprland upstream work?

Not for the MVP. Existing IPC and Wayland protocols cover active window, fullscreen, monitors, idle, and overlays.

Potential upstream proposals only after real-world validation:

1. A structured, stable event indicating active idle inhibitors and their owning surface/application.
2. Better compositor-level visibility into an active screencast indicator if Hyprland already owns that state.
3. A standard protocol or portal for privacy-preserving “presentation/meeting in progress” state—preferably cross-desktop rather than Hyprland-specific.

Do not upstream app-class heuristics, meeting-vendor knowledge, or break-timer policy.

## Optional adapters

### Browser extension

Provides exact tab-level evidence for playing video, conferencing sites, Picture-in-Picture, presentation mode, and screen sharing initiated through WebRTC. It should send only booleans and an origin category, never URLs, titles, page content, or audio.

### Conferencing integrations

Use documented local APIs or D-Bus interfaces where they exist. Avoid accessibility scraping and window-title parsing as primary mechanisms.

### Dictation adapters

Integrate with known dictation tools through explicit start/stop hooks. PipeWire microphone activity remains a fallback heuristic.

### Editor/terminal focus adapters

Probably unnecessary. Hyprland app identity plus recent input activity is sufficient. Editor plugins would add maintenance without materially improving break timing.

## This-machine validation snapshot

Observed on 2026-08-22:

- Hyprland 0.56.2
- PipeWire 1.6.8
- WirePlumber and `wpctl` available
- Chromium exposes an MPRIS player
- Hyprland JSON exposes active-window class and fullscreen state
- A single active monitor was visible during the probe

This proves discovery paths exist; it does not yet prove lifecycle correctness during calls, sharing, dictation, lock, suspend, or multiple monitors.

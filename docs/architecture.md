# Architecture

## Competition architecture

```text
Omarchy Shell / Quickshell process
└── Look Elsewhere plugin
    ├── Service.qml
    │   ├── authoritative timestamps and state transitions
    │   ├── persistence/recovery adapter
    │   ├── idle/fullscreen/media/microphone/dictation evidence
    │   └── IPC and deterministic demo fixtures
    ├── BarWidget.qml
    │   └── bar presentation + quick-panel loader
    ├── Panel.qml
    │   └── status, immediate actions, summary, settings entry
    ├── WarningOverlay.qml
    │   └── top-center warning + final countdown chip
    ├── BreakOverlay.qml
    │   └── per-output break presentation
    ├── Model.js
    │   └── pure transitions, policies, formatting
    └── state/config JSON under XDG state/config locations
```

The competition release is self-contained to preserve one-command installation. Durable state is timestamp-based so the plugin can rehydrate after Quickshell reloads instead of trusting in-memory countdown values.

## Future extraction boundary

If reliability, history volume, cross-shell support, or scheduling complexity outgrows the shell process, the state engine can move behind D-Bus/CLI without changing the visible plugin surfaces. QML must therefore consume an explicit state snapshot and issue commands rather than spreading scheduling truth through presentation bindings.

## Plugin contract

Provisional manifest kinds:

- `service` for resident scheduling/context observation
- `bar-widget` for the bar and nested quick panel
- `overlay` only if a separately summoned/loaded entry point is required by the final runtime design

The prototype must validate whether the overlay is best owned by the resident service or declared independently. The manifest must describe actual loading behavior, not conceptual surfaces.

## Data paths

- Configuration: `${XDG_CONFIG_HOME:-~/.config}/look-elsewhere/config.json`
- Runtime state: `${XDG_STATE_HOME:-~/.local/state}/look-elsewhere/state.json`

Exact schemas will be versioned before implementation. Writes must be atomic. Corrupt or unsupported data must fall back safely with an explanation and without overwriting the original before recovery is possible.

## External integrations

- Quickshell Wayland/idle facilities
- Quickshell Hyprland integration
- Quickshell MPRIS and PipeWire services
- Omarchy indicator/dictation state through the most stable available local contract
- Quickshell IPC for control, inspection, and fixture staging

No integration may require screen capture, audio recording, accessibility-style content scraping, or persistent application-title collection.

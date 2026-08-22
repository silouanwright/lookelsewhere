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
    │   └── status, immediate actions, and summary
    ├── Overlay.qml
    │   └── top-center warning, final chip, and per-output break presentation
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

- Manifest-backed user settings: Omarchy Shell configuration
- Normalized runtime configuration and state: `${XDG_STATE_HOME:-~/.local/state}/look-elsewhere/state.json`

The persisted document is versioned and written atomically. Before release, corrupt/unsupported-state recovery must retain diagnostic evidence rather than silently replacing the original.

## External integrations

- Quickshell Wayland/idle facilities
- Quickshell Hyprland integration
- Quickshell MPRIS and PipeWire services
- Omarchy indicator/dictation state through the most stable available local contract
- Quickshell IPC for control, inspection, and fixture staging

No integration may require screen capture, audio recording, accessibility-style content scraping, or persistent application-title collection.

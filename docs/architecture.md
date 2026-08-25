# Architecture

Reusable presentation controls come from the Qmlpack-managed `oma-ui-kit` source
package under `vendor/qmlpack/oma-ui-kit/Ui` and are imported as `LookUi.*`. The
module composes Omarchy primitives rather than forking the shell design system.
Its generic pattern renderer accepts caller-owned artwork; LookElsewhere keeps
its SVG catalog, theme selection, scheduling, overlays, and break visuals.

## Current architecture

```text
Omarchy Shell / Quickshell process
└── LookElsewhere plugin
    ├── Service.qml
    │   ├── runtime observation and pure-model transition adapter
    │   ├── persistence/recovery adapter
    │   ├── idle/fullscreen/media/microphone/dictation evidence
    │   └── IPC and deterministic demo fixtures
    ├── BarWidget.qml
    │   └── bar presentation + quick-panel loader
    ├── Views/
    │   ├── Panel.qml: popup shell, toolbar, status, actions, and summary
    │   ├── PanelNowView.qml: current-break status and actions
    │   ├── StatsView.qml: private daily summary and bounded session history
    │   ├── SettingsPage.qml: settings, scrolling, and keyboard navigation
    │   └── BreakContent.qml: reusable full-screen break content
    ├── Ui/
    │   ├── RollingClock.qml: one total-seconds presentation queue across minute boundaries
    │   ├── TransientNotice.qml: shared top-centered status/warning pill
    │   ├── product-owned pattern adapter and artwork selection
    │   ├── shared bed icon
    │   └── rolling digit and number controls
    ├── vendor/qmlpack/
    │   ├── oma-ui-kit/Ui: reusable themed controls and rendering primitives
    │   ├── oma-command-layer/Ui: window-scoped shortcuts and key hints
    │   ├── oma-showcase: offscreen themed capture support
    │   └── bounded-read: descriptor-safe state-file reader
    ├── Overlay.qml
    │   └── top-center warning, final chip, and per-output break presentation
    ├── Model.js
    │   └── pure transitions, policies, formatting
    └── scheduler/history JSON under XDG state
```

The plugin commits its Qmlpack lock and vendored source, so it remains
self-contained for one-command installation without requiring end users to
install Qmlpack. Durable
state is timestamp-based so it can rehydrate after Quickshell reloads instead
of trusting in-memory countdown values.

## Future extraction boundary

If reliability, history volume, cross-shell support, or scheduling complexity outgrows the shell process, the state engine can move behind D-Bus/CLI without changing the visible plugin surfaces. QML must therefore consume an explicit state snapshot and issue commands rather than spreading scheduling truth through presentation bindings.

## Plugin contract

- `service` for resident scheduling/context observation
- `bar-widget` for the bar and nested quick panel
- `overlay` for warnings and full-screen break presentation

These are the three kinds declared by `manifest.json`.

## Data paths

- Manifest-backed user settings and sole configuration authority: Omarchy Shell `shell.json`
- Scheduler state, timestamps, and aggregate history: `${XDG_STATE_HOME:-~/.local/state}/look-elsewhere/state.json`

The Options page does not keep a private settings copy. A control change calls
Omarchy Shell's `updateEntryInline()`, which rewrites the LookElsewhere entry in
`~/.config/omarchy/shell.json`. Omarchy injects that updated entry back into the
widget, `Model.configFromSettings()` rebuilds a complete normalized
configuration from manifest defaults plus the stored overrides, and `Service`
applies it immediately.

Settings navigation is local to `Views/SettingsPage.qml`. Each tab exposes one
ordered target list, and every reusable setting control implements the same
`activate()` method. This keeps visual cursor movement, hover selection, and
keyboard activation on one source of truth instead of parallel index tables.

`manifest.json` defines machine-readable defaults and field metadata.
`CONFIGURATION.md` is the human-readable reference for every supported option.
Neither is runtime state, and the scheduler state file never stores user
configuration.

The state document contains no configuration, is versioned, and is written
atomically. Legacy documents containing a `config` field remain readable, but
that field is ignored. Corrupt or unsupported state retains diagnostic evidence
rather than silently replacing the original.

Statistics share that bounded snapshot. They retain seven previous local days
and twelve session outcomes per day, with durations and timestamps only. No
application identity or screen content enters history.

The long-lived shell never ingests an unbounded file or compositor record.
State is loaded through a 64 KiB producer cap while `FileView` remains
write-only, and the active-window fallback is capped and shaped by `jq` before
QML receives it. Active PipeWire node dictionaries are read outside QML only
when the active link topology changes; `tools/pipewire-evidence` caps each node
at 64 KiB and emits only coarse allowlisted evidence. Oversized input fails
closed and preserves the state file.

## External integrations

- Quickshell Wayland/idle facilities
- Quickshell's event-driven Hyprland active-toplevel integration
- Quickshell MPRIS and PipeWire services
- Omarchy dictation state through the same managed status stream used by its native Dictation indicator
- Quickshell IPC for control, inspection, and fixture staging

No integration may require screen capture, audio recording, accessibility-style content scraping, or persistent application-title collection.

## Popup keyboard ownership

The anchored panel uses Omarchy's `KeyboardPanel`, which is a layer-shell
window. Its mnemonic `Shortcut` objects live inside that window's item tree and
use `Qt.WindowShortcut`. This is necessary for both halves of the keyboard
contract:

- shortcuts such as `?`, `B`, `1`, `H`, and `O` work while LookElsewhere owns
  keyboard focus;
- those shortcuts stop immediately when another Omarchy panel takes focus.

Do not move the shortcuts back to the outer `Panel` object. A window-local
shortcut outside the popup tree has no window association and never fires.
Do not replace `Qt.WindowShortcut` with `Qt.ApplicationShortcut`; that allows an
open LookElsewhere instance to intercept keys intended for another shell panel.

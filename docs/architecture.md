# Architecture

Reusable presentation controls live in the internal `Ui/` QML module and are
imported as `LookUi.*`. The module composes Omarchy primitives rather than
forking the shell design system; product-specific scheduling, overlays, and
break visuals remain outside it. See `Ui/README.md` for the ownership boundary.

## Competition architecture

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
    ├── Panel.qml
    │   └── popup shell, toolbar, status, immediate actions, and summary
    ├── SettingsPage.qml
    │   └── settings tabs, scrolling, persistence signals, and keyboard navigation
    ├── Ui/
    │   └── reusable themed controls and shared setting-row contracts
    ├── Overlay.qml
    │   └── top-center warning, final chip, and per-output break presentation
    ├── Model.js
    │   └── pure transitions, policies, formatting
    ├── BedIcon.qml
    │   └── shared full and compact-solid bed artwork
    └── scheduler/history JSON under XDG state
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

- Manifest-backed user settings and sole configuration authority: Omarchy Shell `shell.json`
- Scheduler state, timestamps, and aggregate history: `${XDG_STATE_HOME:-~/.local/state}/look-elsewhere/state.json`

The Options page does not keep a private settings copy. A control change calls
Omarchy Shell's `updateEntryInline()`, which rewrites the LookElsewhere entry in
`~/.config/omarchy/shell.json`. Omarchy injects that updated entry back into the
widget, `Model.configFromSettings()` rebuilds a complete normalized
configuration from manifest defaults plus the stored overrides, and `Service`
applies it immediately.

Settings navigation is local to `SettingsPage.qml`. Each tab exposes one
ordered target list, and every reusable setting control implements the same
`activate()` method. This keeps visual cursor movement, hover selection, and
keyboard activation on one source of truth instead of parallel index tables.

`manifest.json` defines machine-readable defaults and field metadata.
`CONFIGURATION.md` is the human-readable reference for every supported option.
Neither is runtime state, and the scheduler state file never stores user
configuration.

The state document contains no configuration, is versioned, and is written atomically. Legacy documents containing a `config` field remain readable, but that field is ignored. Before release, corrupt/unsupported-state recovery must retain diagnostic evidence rather than silently replacing the original.

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

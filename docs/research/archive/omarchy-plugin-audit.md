# Omarchy Plugin and Reusable-Art Audit

Audit date: 2026-08-22. Read-only inspection of the installed Omarchy shell and user plugin catalog.

## Main finding

The Omarchy integration can reuse substantially more shell infrastructure than expected. The daemon still belongs outside Omarchy Shell, but the plugin can be thin, native-looking, and feature-rich without creating a parallel design system.

## Existing first-party capabilities relevant to the app

| Existing component | Kind | Reusable idea/capability |
|---|---|---|
| `omarchy.reminders` | Overlay | Fullscreen `PanelWindow`, overlay layer, exclusive keyboard focus, scrim, centered themed card, keyboard-first interaction |
| `omarchy.notifications` | Service | Native notification presentation, DND/history semantics |
| `omarchy.idle` | Service | Quickshell `IdleMonitor`, inhibitor-aware idle behavior, activity transitions, lock/screensaver timing |
| `omarchy.media` | Service + bar widget | MPRIS discovery, PipeWire playback-stream correlation, active-player selection, media controls |
| `omarchy.microphone` | Bar widget | PipeWire capture-stream enumeration and a simple “microphone in use” signal |
| `omarchy.indicators` | Bar widget | Existing Dictation, ScreenRecording, Reminder, NightLight, DND, and StayAwake status affordances |
| `omarchy.lock` | Service | Native `WlSessionLock` and Omarchy lock action |
| `omarchy.osd` | Panel | Brief theme-aware status feedback |
| `omarchy.menu` | Menu + bar widget | Fast shell IPC summon pattern and JSON payloads |
| `omarchy.bar` | Bar | Widget placement, shared panel primitives, vertical/horizontal support, tooltips and theme access |

## Important local discoveries

- The current shell already has a **Dictation** indicator category.
- The current shell already has a **ScreenRecording** indicator category.
- `omarchy.microphone` determines whether capture streams exist through Quickshell’s PipeWire service.
- `omarchy.media` combines MPRIS with PipeWire playback-stream presence rather than relying on metadata alone.
- `omarchy.idle` uses `IdleMonitor` with `respectInhibitors: true`.
- `omarchy.reminders` demonstrates a full-output overlay using:

```qml
PanelWindow {
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  exclusionMode: ExclusionMode.Ignore
}
```

- User-installed plugins demonstrate manifest-defined settings schemas, bar panels, service-plus-widget combinations, shell IPC, theme primitives, and external helper processes.

## Plugin shape recommendation

The proposed plugin should declare:

```json
{
  "kinds": ["service", "bar-widget", "overlay"],
  "keepLoaded": true,
  "entryPoints": {
    "service": "Service.qml",
    "barWidget": "BarWidget.qml",
    "overlay": "BreakOverlay.qml"
  }
}
```

Responsibilities:

- `Service.qml` connects to the standalone daemon over D-Bus or a small JSON CLI fallback.
- `BarWidget.qml` renders status and quick actions.
- `BreakOverlay.qml` renders the Omarchy-themed break experience.
- The standalone native overlay remains a fallback when the shell/plugin is unavailable.

## Art and component reuse

Reuse shared Omarchy primitives rather than copying plugin files:

- `Color` for active theme palette
- `Style` for typography, spacing, radius, and animation preferences
- `BorderSurface` and `Border` for cards
- `Panel`, `BarWidget`, `WidgetButton`, `PopupCard`, and shared buttons
- Omarchy icon font/glyph conventions
- Shell summons for OSD or existing panels where appropriate

Do not clone the reminder overlay as the product implementation. Use it as the reference pattern and build a separate plugin whose state comes from the daemon.

## Proposed bar states

| State | Compact bar treatment |
|---|---|
| Working | Optional icon plus `18m`; may be hidden by user |
| Due soon | Accent pulse, `Break in 1m` tooltip |
| Waiting for pause | Subtle animated dot, no layout-width jitter |
| Suppressed | Muted shield/pause icon; tooltip explains context |
| Breaking | Remaining duration |
| Manually paused | Pause icon and resume time |
| Detector uncertain | Small question indicator only when a decision is pending |

The label should use fixed-width formatting to avoid pushing neighboring widgets, following the local system-monitor plugin’s design lesson.

## Proposed popup panel

- Next routine and due time
- Current context decision and evidence summary
- Take break now
- Pause choices
- Today: completed / postponed / skipped
- Link/action to open full settings

Do not put the entire settings application into the bar panel.

## Opportunities for cooperation with Omarchy

No upstream Omarchy work is required for an initial plugin. Potential later improvements:

1. A documented service-to-service interface so third-party plugins can consume idle, media, microphone, dictation, and recording state without duplicating discovery.
2. A public indicator registration API instead of a closed set of indicator implementations.
3. A standard plugin signal for reduced motion and notification-silencing state.
4. A supported way for one plugin to request the lock service without shell-command indirection.

These would benefit other plugins and are better Omarchy contributions than embedding break policy into the shell.

## Installed third-party patterns examined

- `harshith.system-monitor`: manifest settings schema, adaptive bar label, stable width, theme-derived warning colors, rich panel.
- `io.github.keithnyc.omafmail`: combined service and bar widget.
- `mrpbennett.herdr-agents`: service/panel behavior with external helpers.
- `io.github.nilszeilon.omarchy-sensei`: bar widget plus compiled helper pattern.
- `io.github.rafaelsantana6.1passchy`: bridge-process pattern.

These confirm that a daemon-backed bar plugin is conventional within the current ecosystem.

## Update-safety boundary

- Never modify `/usr/share/omarchy/`.
- Develop/install the plugin under `~/.config/omarchy/plugins/<plugin-id>/`.
- Treat private QML implementation details as unstable; prefer documented shared components and validate the manifest with `omarchy plugin validate`.
- Keep the daemon functional when Omarchy APIs change or the plugin is disabled.

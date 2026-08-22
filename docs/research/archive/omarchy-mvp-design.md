# Omarchy Break Coach — MVP and Window Treatment

This proposal applies the `omarchy-plugin-design` skill to the earlier product, detection, state-machine, and LookAway research.

## Product boundary

The MVP is a standalone local break-coach daemon with a first-class Omarchy/Quickshell client. Quickshell owns shell-native presentation and desktop signals. The daemon owns time, schedules, interruption policy, history, restart recovery, and the authoritative state machine.

```text
break-coach daemon
├── active-use and routine clocks
├── interruption/context policy
├── suspend/restart reconciliation
├── local settings and event history
└── D-Bus API + CLI
       │
       └── Omarchy Quickshell plugin
           ├── service adapter
           ├── bar widget + quick panel
           ├── top-center warning
           └── full break overlay
```

This makes the Omarchy experience excellent without making the core unusable on another Wayland shell later.

## MVP behavior

Ship one excellent configurable routine before a library of modalities:

- active-use accumulation with Wayland idle awareness;
- default 20-minute focus interval and 20-second distance break, both editable;
- office-hours schedule, including overnight ranges;
- top-center warning with exact countdown;
- `Start now`, short postpone, and skip according to enforcement mode;
- final compact countdown chip;
- multi-monitor break overlay;
- gentle, balanced, and deliberate enforcement presets;
- fullscreen/video/meeting/dictation suppression when evidence is sufficiently confident;
- natural-pause start, post-protected-context cooldown, and ambiguous-idle handling;
- temporary pause modes and resume time;
- local counts for prompted, completed, postponed, skipped, and suppressed;
- restart/suspend recovery;
- CLI/D-Bus operations and deterministic Quickshell IPC staging.

Defer routine libraries, exercise coaching, cloud/mobile sync, website statistics, health scoring, camera inference, app-specific extensions, and elaborate analytics. Make the adapter boundary ready for them, but do not expose inert configuration.

## Omarchy plugin kinds

The plugin should declare:

- `service`: subscribes to daemon state and maps Omarchy context signals;
- `bar-widget`: glanceable status and quick panel;
- `overlay`: warning/countdown/break surfaces.

Use `keepLoaded` because timing presentation and context updates must remain available. The service must reconnect gracefully when the daemon restarts. It must never become the authoritative clock.

## Surface map

### Bar widget

Show one quiet symbol plus a useful state:

- normal: time until next break, optionally compacted to icon-only;
- due soon: subtle accent/progress treatment;
- paused: pause glyph and resume time in tooltip/panel;
- protected context: small shield/hold treatment;
- daemon unavailable: disconnected state, not a misleading timer.

Click opens the quick panel. Avoid animation except a brief transition when state changes.

### Quick panel

Use native `Panel` + `PopupCard`, current compact width, fitted height, and Omarchy tokens.

Hierarchy:

1. `PanelHero`: “Next eye break” with exact time/status and a small pause/settings action.
2. One primary action that changes with state: `Take break now`, `Resume`, or `Reconnect`.
3. Compact current-routine row: focus interval, break duration, office-hours status.
4. Smart-context explanation when delayed: “Waiting until your meeting ends” with evidence category, not invasive metadata.
5. Today summary: completed, postponed, skipped.
6. Footer actions: pause menu and `Open settings`.

Do not place full routine editing, detector thresholds, enforcement configuration, history charts, or onboarding in the popup.

### Top-center warning

This is a Quickshell layer-shell surface, visually derived from Omarchy rather than macOS glass.

- Anchor top center with safe distance below the bar/output edge.
- Width should fit a short message and one action row; clamp to available output width.
- Use a themed `BorderSurface`, native typography, and restrained elevation/border.
- Show precise countdown, calm one-line reason, `Start now`, and the allowed postpone actions.
- Enter activates the primary action; Escape follows enforcement policy; number/letter shortcuts may postpone only when visibly labeled.
- Do not request exclusive keyboard focus during ordinary warnings. Raise focus only when the chosen enforcement mode makes the surface intentionally modal.
- Keep position stable as the countdown changes.

### Final countdown chip

Replace the action card for the last 3–5 seconds with a smaller top-center chip. It should communicate inevitability without flashing, bouncing, or growing. Reduced-motion mode uses an instantaneous card-to-chip switch.

### Break overlay

Use one layer-shell surface per selected output, with a single authoritative interactive instance on the focused output.

- Theme-aware darkening/background treatment; no fixed pink gradient.
- Central short instruction: “Look at something far away” and remaining time.
- Optional secondary cue such as a slow static-to-minimal breathing ring, disabled under reduced motion.
- Balanced mode reveals skip only after its configured delay. Deliberate mode clearly explains the emergency exit before activation.
- Keyboard focus is exclusive only while enforcement requires it, with a documented escape chord.
- Monitor hotplug must not duplicate actions or reset the break.

## Settings surface

The LookAway-sized configuration shown in the reference screenshot should be a dedicated settings surface, not squeezed into the bar popup. For MVP, it may be a larger Quickshell `PanelWindow`/window if native controls, accessibility, focus traversal, and window management are adequate; otherwise use a small native application over the same daemon API. Quickshell remains the preferred first spike.

Navigation:

- **Overview:** enabled state, next break, current routine, today, pause control.
- **Breaks:** interval, duration, office hours, long-break cadence.
- **Smart Context:** idle credit, meeting/media/dictation/fullscreen behavior, cooldown, plain-language detector status.
- **Enforcement:** Gentle/Balanced/Deliberate cards with exact consequences and snooze budget.
- **Experience:** break message, outputs, sound, motion/reduced motion.
- **System:** startup, shortcuts, Omarchy integration, privacy/data controls, diagnostics.

Use progressive disclosure. Presets write editable values. Advanced confidence thresholds remain collapsed unless diagnostics or expert mode is enabled.

## Visual language

- Inherit the active Omarchy font, palette, spacing, borders, radius, control states, and bar position.
- Use personality through a single recognizable eye/rest glyph, calm copy, and information design—not custom chrome.
- Prefer spatial grouping to nested cards.
- One accent color at a time; urgent color only for true error/destructive states.
- Maintain stable dimensions across timer ticks and async transitions.
- Design dark, light/high-contrast, rounded, and sharp-corner themes from the start.

## MVP acceptance bar

Before calling the UI complete:

- manifest validates and QML starts without runtime warnings;
- daemon remains authoritative through shell reload, daemon restart, suspend, and monitor changes;
- warning, chip, and overlay are captured on the active theme and one contrasting theme;
- all surfaces work keyboard-only;
- normal, paused, protected-context, disconnected, loading, empty-history, warning, postponed, breaking, and completion states are visually verified;
- top/bottom bars and output scaling do not clip the popup or warning;
- multi-monitor behavior has exactly one interactive authority;
- no title, URL, meeting name, transcript, or media metadata is logged or displayed by default.

## First implementation slice

Build this vertical slice first:

1. Daemon with one editable routine, active-use timer, persistence, CLI/D-Bus, and restart recovery.
2. Quickshell service adapter and bar widget.
3. Native quick panel with take-now/pause/reconnect and detector explanation.
4. Top-center warning, final chip, and timed multi-monitor overlay.
5. Settings for schedule, timing, three enforcement presets, core context toggles, sound, and reduced motion.
6. State fixtures/IPC methods that make every visual state capturable without waiting in real time.

That slice proves the differentiator: excellent interruption judgment delivered through a native Omarchy experience.

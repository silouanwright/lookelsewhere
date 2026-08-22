# Look Elsewhere

Look Elsewhere is a private, context-aware break coach built natively for Omarchy. It counts active screen use, waits through protected moments such as meetings, media, fullscreen work, and dictation, then delivers a calm warning and break at a better moment.

The repository currently contains a runnable competition prototype: a resident scheduling service, bar widget, anchored quick panel, progressive warning, final countdown, and theme-aware multi-monitor break overlay. The remaining release work is tracked in the [completion matrix](docs/completion-matrix.md).

## Product promise

> Look Elsewhere finds the right moment to pull your attention away from the screen.

The competition MVP is a self-contained Omarchy Shell plugin written with Quickshell/QML. It observes only coarse local state. It does not record audio, capture the screen, retain window or media titles, require an account, or send telemetry.

## Current capabilities

- Active-use scheduling with timestamp persistence and recovery
- Idle, Hyprland fullscreen, MPRIS playback, PipeWire microphone, and Omarchy dictation evidence
- Confidence-based protected-context delay and cooldown
- Gentle, Balanced, and Focused enforcement policies
- Omarchy-native bar, popup, warning, countdown, and break surfaces
- Manifest-backed configuration for timing, office hours, detectors, enforcement, snoozing, and reduced motion
- One interactive authority across multiple outputs
- Deterministic IPC demo states that do not persist synthetic data
- Theme-role integration for contrasting Omarchy themes

## Development preview

With the plugin installed and enabled:

```bash
omarchy-shell look-elsewhere demo protected
omarchy-shell look-elsewhere demo warning
omarchy-shell look-elsewhere demo final
omarchy-shell look-elsewhere demo break
omarchy-shell look-elsewhere demoOff
```

These fixtures are development tools. They restore the pre-demo snapshot and never write synthetic state.

## Configuration

The competition MVP follows Omarchy's config-first plugin convention. Settings live in the plugin's bar-widget entry in `~/.config/omarchy/shell.json`; use the supported CLI to update them without editing JSON by hand:

```bash
omarchy bar set io.github.silouanwright.look-elsewhere focusMinutes 25 --json
omarchy bar set io.github.silouanwright.look-elsewhere breakSeconds 45 --json
omarchy bar set io.github.silouanwright.look-elsewhere enforcement '"balanced"' --json
omarchy bar set io.github.silouanwright.look-elsewhere officeHoursEnabled true --json
omarchy bar set io.github.silouanwright.look-elsewhere reducedMotion false --json
```

The complete typed contract, defaults, ranges, and descriptions are declared in [`manifest.json`](manifest.json). A dedicated graphical settings client is intentionally deferred until after the competition MVP.

## Install

The public repository is not published yet. Once available:

```bash
omarchy plugin add https://github.com/silouanwright/look-elsewhere.git --enable
```

Disable or remove it safely with:

```bash
omarchy plugin disable io.github.silouanwright.look-elsewhere
omarchy plugin remove io.github.silouanwright.look-elsewhere
```

Look Elsewhere has no installer hook, privileged operation, external daemon, account, or network dependency.

## Project identity

- Author: Silouan Wright
- Plugin ID: `io.github.silouanwright.look-elsewhere`
- License: MIT
- Runtime target: Omarchy Quattro / Omarchy Shell
- Source repository: `silouanwright/look-elsewhere`

## Documentation

Product behavior, architecture, privacy boundaries, research, ADRs, verification, and competition delivery live under [`docs/`](docs/README.md).

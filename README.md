# Look Elsewhere

Look Elsewhere is a privacy-conscious, context-aware break coach built natively for Omarchy. It counts active screen use, waits through protected moments such as meetings, media, fullscreen work, and dictation, then delivers a calm warning and break at a better moment.

![Look Elsewhere break overlay](preview.png)

The repository contains a resident scheduling service, bar widget, anchored quick panel, progressive warning, final countdown, and theme-aware multi-monitor break overlay. Release verification is tracked in the [completion matrix](docs/completion-matrix.md).

## Product promise

> Look Elsewhere finds the right moment to pull your attention away from the screen.

The competition MVP is a self-contained Omarchy Shell plugin written with Quickshell/QML. It observes only coarse local state. It does not record audio, capture the screen, retain window or media titles, require an account, or send telemetry.

## From glance to break

The bar countdown opens a compact, anchored control surface. When focused use
reaches its final seconds, Look Elsewhere progresses from a top-centered warning
to a small final countdown and then a calm, theme-aware break surface.

| Anchored quick panel | Progressive warning |
|---|---|
| ![Look Elsewhere anchored quick panel](docs/assets/quick-panel.png) | ![Look Elsewhere top-centered warning](docs/assets/progressive-warning.png) |

Periodic long breaks use the same calm surface, with a compact status pill that
explains the longer countdown without rewriting the user-configured guidance.

![Look Elsewhere long-break overlay](docs/assets/long-break.png)

[Watch the 21-second deterministic warning-to-break demo](docs/assets/demo.mp4).
The capture uses synthetic fixture state, does not inspect private context, and
returns the real schedule unchanged when it ends.

## Current capabilities

- Active-use scheduling with timestamp persistence and recovery
- Idle, Hyprland fullscreen, focused-app MPRIS playback, PipeWire microphone, and Omarchy dictation evidence
- Confidence-based protected-context delay and cooldown
- Wayland-native natural-pause timing before a due warning
- Casual, Balanced, and Hardcore enforcement policies
- Configurable short breaks and periodic long breaks
- Omarchy-native bar, popup, warning, countdown, and break surfaces
- Keyboard-native operation with global invocation, complete focus traversal, direct action keys, and persistent visual hints
- Manifest-backed configuration for timing, office hours, detectors, enforcement, snoozing, and reduced motion
- One interactive authority across multiple outputs
- Deterministic IPC demo states that do not persist synthetic data
- Theme-role integration for contrasting Omarchy themes

## Development preview

With the plugin installed and enabled:

```bash
omarchy-shell look-elsewhere demo protected
omarchy-shell look-elsewhere demo meeting
omarchy-shell look-elsewhere demo microphone
omarchy-shell look-elsewhere demo media
omarchy-shell look-elsewhere demo fullscreen
omarchy-shell look-elsewhere demo dictation
omarchy-shell look-elsewhere demo idle
omarchy-shell look-elsewhere demo flow
omarchy-shell look-elsewhere demo long-break
omarchy-shell look-elsewhere demo warning
omarchy-shell look-elsewhere demo final
omarchy-shell look-elsewhere demo break
omarchy-shell look-elsewhere demo casual-break
omarchy-shell look-elsewhere demo hardcore-break
omarchy-shell look-elsewhere demo recovery
omarchy-shell look-elsewhere demoOff
```

These fixtures are development tools. They restore the pre-demo snapshot and never write synthetic state.

## Configuration

The competition MVP follows Omarchy's config-first plugin convention. Settings live in the plugin's bar-widget entry in `~/.config/omarchy/shell.json`; use the supported CLI to update them without editing JSON by hand:

```bash
omarchy bar set io.github.silouanwright.look-elsewhere focusMinutes 25 --json
omarchy bar set io.github.silouanwright.look-elsewhere breakSeconds 45 --json
omarchy bar set io.github.silouanwright.look-elsewhere longBreakEvery 4 --json
omarchy bar set io.github.silouanwright.look-elsewhere longBreakSeconds 180 --json
omarchy bar set io.github.silouanwright.look-elsewhere enforcement '"balanced"' --json
omarchy bar set io.github.silouanwright.look-elsewhere officeHoursEnabled true --json
omarchy bar set io.github.silouanwright.look-elsewhere reducedMotion false --json
omarchy bar set io.github.silouanwright.look-elsewhere soundEnabled true --json
omarchy bar set io.github.silouanwright.look-elsewhere breakTitle '"Look Elsewhere"' --json
omarchy bar set io.github.silouanwright.look-elsewhere breakSubtitle '"Look across the room and breathe."' --json
omarchy bar set io.github.silouanwright.look-elsewhere soundVolume 65 --json
omarchy bar set io.github.silouanwright.look-elsewhere startSoundEnabled true --json
omarchy bar set io.github.silouanwright.look-elsewhere completionSoundEnabled true --json
omarchy bar set io.github.silouanwright.look-elsewhere startSoundPath '"/absolute/path/to/start.ogg"' --json
omarchy bar set io.github.silouanwright.look-elsewhere completionSoundPath '"~/Sounds/complete.ogg"' --json
omarchy bar set io.github.silouanwright.look-elsewhere outputMode '"all"' --json
omarchy bar set io.github.silouanwright.look-elsewhere displayMode '"icon-and-time"' --json
omarchy bar set io.github.silouanwright.look-elsewhere showKeyboardHints true --json
omarchy bar set io.github.silouanwright.look-elsewhere shortcutBreakNow '"Ctrl+K"' --json
```

`displayMode` accepts `icon`, `time`, or `icon-and-time`. The compact countdown shows minutes, then switches to seconds during the final minute. Vertical bars use the icon so the widget remains legible.

Look Elsewhere enables two bundled piano cues by default: an ascending phrase
when a break begins and a resolving phrase when it is time to return.
`soundEnabled` is the master switch; the two per-cue switches can disable only
one transition. `soundVolume` controls both cues from 0–100 independently of
other applications, while system output volume remains the final ceiling.
Set either custom path to an absolute or `~/` audio-file path; an empty path
restores the bundled cue. Demo fixtures and state restoration never replay
either sound.

The complete typed contract, defaults, ranges, and descriptions are declared in [`manifest.json`](manifest.json). A dedicated graphical settings client is intentionally deferred until after the competition MVP.

Inspect or reset private local state with:

```bash
omarchy-shell look-elsewhere diagnostics
omarchy-shell look-elsewhere resetLocalData
```

`resetLocalData` removes the local schedule and aggregate outcome history on the next atomic state write. It does not change Omarchy configuration.

Enforcement behavior is explicit: Casual and Balanced permit bounded snoozing
and ordinary skipping. Hardcore still permits bounded snoozing, but the active
break cannot be skipped and ends only when its timer completes. Legacy
`gentle` and `focused` configuration values migrate to Casual and Hardcore.

## Keyboard-native control

LookElsewhere is designed to be fully operated without a pointer. The anchored
panel takes keyboard focus when opened; Tab and Shift+Tab traverse every control
in a closed loop, Enter or Space activates the focused control, and Escape closes
the panel without changing preferences. Direct action keys make frequent paths
immediate, while `?` reveals persistent, theme-aware shortcut badges. Shortcuts
automatically deactivate when another Omarchy surface takes keyboard focus.

| Key | Action |
|---|---|
| `b` | Start a break now |
| `1` / `2` / `3` | Snooze for 1 / 5 / 15 minutes when policy allows |
| `p` | Pause or resume scheduled breaks |
| `h` | Toggle break history |
| `o` | Toggle options |
| `e` | Edit settings while Options is open |
| `Shift+d` | Stop and disable LookElsewhere while Options is open |
| `?` | Toggle visible key hints for every action; the choice persists for the shell session |
| `q` or `Esc` | Close the panel without changing key-hint visibility |

The direct action keys are manifest-backed settings (`shortcutBreakNow`,
`shortcutSnooze1`, `shortcutSnooze5`, `shortcutSnooze15`, `shortcutPause`,
`shortcutHistory`, `shortcutOptions`, `shortcutEdit`, `shortcutDisable`,
`shortcutClose`, and `shortcutHints`). They accept a letter, digit, `?`, F1–F12,
or a chord using Ctrl, Alt, Shift, or Meta. Invalid or conflicting values fall
back to the documented defaults, and visible badges always show the effective
binding. Tab, Shift+Tab, Enter, Space, and Escape remain fixed accessibility
conventions.

LookElsewhere does not silently claim global keys. For first-class invocation
from anywhere, add the recommended `Super+Alt+L` binding to
`~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + ALT + L", "LookElsewhere", "omarchy-shell look-elsewhere-panel toggle")
```

Optional direct-action bindings can sit beside it:

```lua
o.bind("SUPER + ALT + B", "Take an eye break", "omarchy-shell look-elsewhere takeBreak")
o.bind("SUPER + ALT + P", "Pause or resume eye breaks", "omarchy-shell look-elsewhere togglePause")
```

Check `omarchy menu keybindings --print` before adopting the recipe if you have
custom bindings. IPC remains available for different key choices and scripts.

## Install

```bash
omarchy plugin add https://github.com/silouanwright/look-elsewhere.git --enable
```

Disable or remove it safely with:

```bash
omarchy plugin disable io.github.silouanwright.look-elsewhere
omarchy plugin remove io.github.silouanwright.look-elsewhere
```

Look Elsewhere requires Omarchy Quattro with Omarchy Shell. It has no installer
hook, privileged operation, external daemon, account, or network dependency.
Its optional break sound uses `canberra-gtk-play` when available; the scheduler
and all visual behavior continue normally without it.

## Limitations and upstream work

### Video detection is currently inferred

MPRIS 2.2 reports playback state, application identity, controls, and generic
track metadata, but it does not standardize whether the current item contains
audio, video, or both. `SupportedMimeTypes` describes everything a player can
open; it does not describe the item currently playing. Chromium similarly
exports its active browser media session through MPRIS without exposing whether
that session has a video track.

Look Elsewhere therefore treats playback as video only when the MPRIS player's
application matches the focused Hyprland application. This deliberately ignores
background music, but it remains a heuristic: a focused music player or music
tab can be labeled `Video`, while a player with incomplete application identity
can be missed. PipeWire is not a generic fallback because browsers normally
render video directly and expose only their audio stream to PipeWire.

The complete upstream fix requires coordinated patches:

1. **MPRIS specification:** add optional current-item stream information, such
   as `mpris:mediaTypes = ["audio", "video"]`. A stream-type list is preferable
   to a MIME type because browser blobs and adaptive streams may not have a
   useful content MIME type.
2. **Chromium:** map its internal media-session audio/video state to the new
   metadata and emit `PropertiesChanged` when that state changes.
3. **Firefox:** export the equivalent state for its active browser media
   session.
4. **Native players:** mpv, VLC, and other MPRIS exporters should publish the
   field from their decoded track information when available.
5. **Look Elsewhere:** prefer the standardized field, retain focused-app MPRIS
   as an explicit compatibility fallback, and report uncertainty rather than
   silently claiming exact detection.

Quickshell does not currently require an upstream patch for basic support: its
MPRIS player already exposes the raw metadata map. A typed convenience property
could be added later, after the MPRIS field is standardized. Until then, a
browser extension that inspects the active tab's playing media element is the
most accurate browser-specific integration.

References: [MPRIS Player interface](https://specifications.freedesktop.org/mpris/latest/Player_Interface.html),
[MPRIS metadata map](https://specifications.freedesktop.org/mpris/latest/Track_List_Interface.html),
[Chromium MPRIS implementation](https://chromium.googlesource.com/chromium/src/+/b9c645c0b167a38b8f93b6c9e9f5a6a2f3e854ae/ui/base/mpris/mpris_service_impl.cc),
and [PipeWire media-type keys](https://docs.pipewire.org/1.4/group__pw__keys.html).

## Project identity

- Author: Silouan Wright
- Plugin ID: `io.github.silouanwright.look-elsewhere`
- License: MIT
- Runtime target: Omarchy Quattro / Omarchy Shell
- Source repository: `silouanwright/look-elsewhere`

## A note from Silouan

I voluntarily stepped away from full-time work about a year ago. After twenty
years as an engineer, I know what I want to return for: work I genuinely love,
with the freedom to use agentic coding as deeply as the work deserves.

Look Elsewhere is a demonstration of how I work. I care about the last
few pixels, but also the state model beneath them; I research unfamiliar
territory until I understand the real constraints, turn that research into
clear product decisions, and communicate what is wrong precisely enough to fix
it. I move comfortably between product strategy, interaction design, systems
engineering, debugging, documentation, and release discipline. Omarchy feels
like the kind of product and community I would love to help build full time.

I built this project in close collaboration with an AI coding agent, from the
first research question through product decisions, ADRs, implementation, live
visual iteration, debugging, and release verification. That process is part of
the work sample. I can direct agents across a long, complex effort without
outsourcing judgment: recognize when something merely passes versus actually
feels right, explain why, separate a stale deployment from a flawed design, and
keep product quality, technical truth, and scope aligned. The long development
record also shows persistence without aimlessness: test an assumption, inspect
the evidence, revise the implementation or the direction, and preserve what was
learned so the next iteration starts further ahead.

I am entering because I want to contribute, not for the prize. If Look Elsewhere
wins, I will donate the prize money to charity. More than anything, I would love
the opportunity to get back to work with people building something this alive.

## Documentation

Product behavior, architecture, privacy boundaries, research, ADRs, verification, and competition delivery live under [`docs/`](docs/README.md).

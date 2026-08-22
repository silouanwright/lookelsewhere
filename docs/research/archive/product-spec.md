# Product Specification

## Product statement

A local-first, Wayland-native recovery coach that schedules multiple kinds of breaks and chooses minimally disruptive moments using explainable desktop context.

## Target users

Primary design partners:

- Hyprland and Omarchy users working at a computer for long sessions
- Developers, designers, writers, students, and remote workers
- Users who currently dismiss rigid timers
- Users who want visual-rest, movement, posture, pacing, or focus routines

The product is a wellness and workflow tool, not a medical device.

## Core concepts

### Routine

```text
Routine
  id, name, enabled
  modality: visual_refocus | blink | mobility | posture | breathing |
            cognitive | pomodoro | pacing | planned | custom
  trigger: active_use | wall_clock | session_elapsed | manual
  interval / scheduled times
  duration
  grace period
  idle completion threshold
  interruption policy
  enforcement level
  work-hour scope
  content card set
  start/end hooks
```

### Interruption policy

```text
Policy
  suppress_when_locked = true
  suppress_when_fullscreen = ask | always | never
  suppress_when_media = ask | always | never
  suppress_when_meeting = always
  natural_pause_wait = duration
  maximum_overdue = duration
  postpone_choices = [5m, 15m, 30m]
  postpone_budget = count per routine/session/day
```

### Enforcement

- **Gentle:** notification and optional overlay
- **Focused:** fullscreen overlay with immediate skip
- **Deliberate:** skip appears after a delay or requires a press-and-hold
- **Locked:** invoke the configured lock command

## MVP requirements

### Scheduling

- Active-use time excludes qualifying idle periods.
- Multiple routines may coexist without colliding.
- A long break can satisfy or defer nearby short routines.
- Planned clock-time breaks survive daemon restarts.
- Missed breaks follow an explicit catch-up policy; they do not all fire on resume.

### Context

- Wayland idle state
- Hyprland active app class and fullscreen state
- Lock and suspend lifecycle
- MPRIS playback state
- User-defined application policies
- Explainable suppression reason

### Presentation

- Heads-up notification before a break
- Natural-pause waiting state
- Multi-output break overlay
- Keyboard-accessible controls
- Reduced-motion mode
- High contrast and scalable typography
- No color-dependent-only state communication

### Control surfaces

- Native settings application
- CLI
- D-Bus API
- Omarchy Shell bar plugin
- Desktop notification actions

### Full settings navigation

- General
- Routines
- Smart Context
- Enforcement
- Break Experience
- Alerts
- Sounds
- Shortcuts
- Automation
- Omarchy
- Privacy and diagnostics

The bar popup intentionally exposes only status and frequent actions. Complex configuration lives in the full settings client.

### Local data

- Configuration file
- Current durable scheduler state
- Aggregate event history: due, completed, skipped, postponed, suppressed
- Optional retention period
- No window titles, URLs, keystrokes, media names, audio, video, or screenshots

## Default routines

Defaults are onboarding choices, not medical prescriptions:

1. **Eye reset:** short distant-focus break after a configurable active-use interval.
2. **Move:** longer stand/walk/stretch break after sustained active use.
3. **Deep focus:** Pomodoro-like focus and recovery blocks.
4. **Gentle pacing:** user-adjustable frequent recovery breaks.
5. **Custom:** arbitrary cadence, content, and policy.

Only enable routines the user explicitly selects during onboarding.

## D-Bus and CLI contract

Suggested bus name: `org.waylandbreak.Coach1` (placeholder until naming).

Read methods/signals:

- `GetState()`
- `ListRoutines()`
- `GetContextDecision()`
- `StateChanged`
- `ContextChanged`
- `RoutineDue`

Actions:

- `Pause(until)`
- `Resume()`
- `StartBreak(routine_id)`
- `Postpone(routine_id, duration)`
- `Skip(routine_id)`
- `EndBreak()`
- `ReloadConfiguration()`

CLI mirrors the API:

```text
break-coach status --json
break-coach pause 30m
break-coach resume
break-coach break start eye-reset
break-coach postpone 10m
break-coach context explain
```

## Architecture

```text
Daemon
├── monotonic scheduler
├── routine coordinator
├── evidence registry
├── policy evaluator
├── local persistence
├── D-Bus service
└── adapters
    ├── Wayland idle
    ├── Hyprland IPC
    ├── login1
    ├── MPRIS
    └── PipeWire (post-MVP)

Clients
├── native overlay
├── native settings UI
├── CLI
└── Omarchy QML plugin
```

The daemon is authoritative. All clients can disappear and reconnect without changing scheduler state.

## Omarchy integration

The plugin lives in the user plugin directory and communicates only through D-Bus/CLI. It provides:

- Bar countdown/status
- Pause/resume/take-break menu
- Current suppression reason
- Theme-derived colors and typography
- Optional Omarchy-native break overlay

The native overlay remains installed as a fallback. If Omarchy Shell disconnects, the daemon uses the native overlay for the next break.

## Technology decision

Do not lock the toolkit before the protocol spike.

Two credible paths:

1. **C++/Qt 6 + QML:** shortest route to polished QML UI and `layer-shell-qt`; one language/runtime for daemon and UI, but greater C++ complexity.
2. **Rust daemon + QML client:** stronger daemon ergonomics and clean D-Bus/protocol code, but adds an FFI/process boundary and packaging work.

Reject Electron for the core: its known Wayland idle and multi-display limitations reproduce the problem being solved.

## Milestones

### M0 — protocol proof

- Observe idle/resume
- Observe Hyprland fullscreen/app changes and reconnect safely
- Observe MPRIS transitions
- Render overlays on all outputs
- Survive monitor hotplug and compositor reconnect

### M1 — usable private alpha

- One active-use routine
- Warning, grace period, overlay, postpone, skip
- Settings file, CLI, durable state
- Lock/suspend handling

### M2 — product-shaped alpha

- Multiple routine modalities
- Work hours and planned breaks
- History and adherence summaries
- Native settings UI
- Omarchy bar plugin

### M3 — smart context beta

- Confidence-scored MPRIS/fullscreen/app policies
- PipeWire microphone/camera/media evidence
- Browser adapter experiment
- Decision explanations and corrections

## Success criteria

- A user can run it for five workdays without disabling it out of frustration.
- Fewer than 5% of breaks appear during explicitly protected contexts.
- No timer reset or duplicate break after shell/daemon restart, suspend, or monitor change.
- Context decisions always have a human-readable explanation.
- Idle CPU usage is negligible and memory use is appropriate for a native desktop service.
- The app remains useful with every optional smart detector disabled.

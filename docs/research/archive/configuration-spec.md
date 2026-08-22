# Configuration and Polish Specification

## Configuration principles

1. Defaults must produce a useful experience without opening advanced settings.
2. Every automated behavior has a visible explanation and a correction path.
3. Presets generate editable configuration rather than locking users into modes.
4. Configuration complexity is organized by user intent, not subsystem.
5. The CLI, file format, native settings client, and Omarchy plugin all operate on the same daemon schema.

## Suggested schema outline

```yaml
version: 1

general:
  enabled: true
  work_hours_profile: default
  reduced_motion: system
  history_retention_days: 30

presentation:
  warning:
    enabled: true
    lead_seconds: 30
    outputs: active
    position: top-center
  final_countdown:
    enabled: true
    seconds: 3
    position: top-left
  overlay:
    renderer: auto
    outputs: all
    background: theme
    show_countdown: initially
  sound:
    respect_dnd: true

context:
  natural_pause_seconds: 5
  protected_exit_cooldown_seconds: 60
  detectors:
    fullscreen: ask
    mpris_media: foreground
    microphone: communication-only
    screen_capture: auto
  app_rules: []

enforcement:
  mode: deliberate
  skip_delay_seconds: 5
  snooze_budget:
    scope: session
    count: 3

routines: []

automation:
  hooks: []

omarchy:
  bar_mode: adaptive
  overlay: preferred
  use_indicators: true
  lock_command: omarchy-system-lock
```

Names are illustrative. The production schema should use duration types that cannot confuse seconds and milliseconds.

## Routine editor sections

### Identity

- Name
- Icon
- Modality/content
- Enabled

### When

- Active-use interval, wall-clock time, session elapsed, or manual only
- Repeat days
- Work-hours relationship
- Timezone and travel behavior for planned routines

### Duration and satisfaction

- Full duration
- Minimum duration eligible for early End
- Idle duration that satisfies it
- Whether a longer routine satisfies this routine

### Interruption

- Warning lead time override
- Natural-pause behavior
- Protected-context policy override
- Maximum overdue
- Post-activity cooldown

### Presentation

- Overlay content/background
- Output placement
- Sound
- Countdown visibility

### Enforcement

- Inherit global or override
- Snooze choices
- Snooze/skip budget
- Lock behavior

### Automation

- Start, completion, skip, and end hooks

## Smart Context settings

Each detector row contains:

- State icon
- Detector name
- Current status
- Policy control
- “Details” page

The details page contains:

- Plain-language explanation
- Live sanitized evidence
- Confidence and freshness
- App/device allow/exclude rules
- Test instructions
- Recent decisions attributable to that detector

Avoid presenting a single giant list of raw PipeWire nodes or bus names as the primary interface.

## Enforcement preview cards

Show behavior rather than only names:

- Gentle: visible enabled Skip button
- Deliberate: disabled Skip button with short countdown/hold affordance
- Locked: lock symbol and explicit escape/recovery explanation

Selecting a card updates a one-sentence consequence beneath it. Strong enforcement requires confirmation and must explain the emergency exit.

## Polish requirements by release

### Alpha polish floor

- No timer width jitter
- No duplicate notifications
- Correct focus restoration
- Smooth monitor hotplug
- Reliable resume after restart/suspend
- All actions reachable by keyboard
- Test buttons for every presentation surface

### Beta polish floor

- Theme changes apply live
- Reduced motion is complete, not partial
- Sound previews and DND behavior are predictable
- Multi-monitor placement is configurable and tested
- Detector explanations and correction rules are coherent
- Empty, loading, permission-denied, disconnected, and error states are designed

### 1.0 polish floor

- Onboarding presets are tested with new users
- Settings search and aliases
- Import/export with validation report
- Accessibility review
- Performance budget and idle-resource telemetry available locally
- Documentation includes screenshots for every major state

## Performance budgets

Targets, to validate rather than promise prematurely:

- Idle CPU effectively zero/event-driven
- No polling faster than necessary
- Memory target below 50 MB for daemon; UI memory measured separately
- Warning visible within 100 ms of a daemon state signal
- Omarchy Quick Panel opens without spawning heavy helpers
- Animated backgrounds suspend when hidden and honor battery/reduced-motion policy

## Usability test scenarios

1. Set up an eye routine without touching advanced settings.
2. Explain why a break was delayed during a browser video.
3. Correct a false meeting detection caused by dictation software.
4. Create an overnight work schedule.
5. Understand the difference between postpone, skip, and end.
6. Recover from an accidentally selected strong enforcement mode.
7. Configure warnings on only the active monitor and breaks on all monitors.
8. Preview sounds and overlays without affecting the real schedule.
9. Export configuration and inspect what history is stored.
10. Restart Omarchy Shell during a break without losing state.

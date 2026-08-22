# LookAway Observations

Observations from user-provided reference captures. These describe interaction and information architecture, not visual assets to reproduce.

## Pre-break warning

- The primary warning is a floating card near the top center of the active display.
- It presents a precise live countdown rather than only saying “soon.”
- Supporting copy is short and reassuring.
- The primary action starts the break immediately.
- Postponement choices are visible inline: one, five, and fifteen minutes.
- During the final seconds, a separate compact chip announces “Starting break in N.”
- Menu-bar status remains visible and displays the broader time-to-break state.

### Requirement derived

Implement progressive escalation:

```text
bar status → top-center heads-up → final countdown chip → break overlay
```

Each stage must have its own configurable visibility and sound policy. The final countdown should be short enough to communicate the transition without becoming a second postponement interface.

## Settings information architecture

The reference uses a persistent categorized sidebar:

- General
- Screen Breaks
- Smart Pause
- Wellness Reminders
- Alerts / Nudges
- Sounds
- Keyboard Shortcuts
- iPhone Sync
- Automation
- About

Screen Breaks contains:

- Active/focused screen-time interval
- Break duration
- Break-screen customization
- Long-break cadence and duration
- Office hours
- Enforcement presented as Casual, Balanced, and Hardcore
- Daily snooze allowance

The enforcement choices are visually demonstrated rather than hidden in a select menu. That is a strong pattern because users can understand the behavioral consequence before selecting it.

## Omarchy-adapted information architecture

### General

- Start automatically
- Show bar widget
- Work profile/default preset
- Reduced motion
- Data retention

### Routines

- Eye reset
- Long/movement break
- Posture, blink, breathing, pacing, Pomodoro, and custom routines
- Active-use interval, duration, long-break combination, and planned schedules

This replaces a single “Screen Breaks” page because the proposed product supports multiple modalities.

### Smart Context

- Natural-pause detection
- Idle completion/reset behavior
- Fullscreen policy
- Media playback policy
- Meeting/dictation/capture evidence
- Per-application correction rules
- Live “why” explanation

Use “Smart Context,” not “Smart Pause,” because the engine may allow, delay, ask, suppress, or consider a break satisfied.

### Enforcement

- Gentle: notification/overlay with immediate skip
- Focused: full overlay with immediate skip
- Deliberate: skip after a delay or press-and-hold
- Locked: invoke Omarchy’s lock service
- Daily/session postponement budget

Avoid the label “Hardcore.” It is memorable but not descriptive or accessibility-oriented.

### Break Experience

- Background: theme color, dimmed wallpaper, gradient, custom image
- Message/content cards
- Countdown visibility
- Multi-monitor placement
- End sound
- Reduced motion

### Alerts

- Advance-warning lead time
- Final countdown chip
- Overtime nudge
- Notification behavior
- DND interaction

### Sounds

- Warning/start/end sounds
- Volume
- Custom sounds
- Respect system DND

### Shortcuts

- Take break now
- Pause/resume
- Postpone
- End/skip where policy permits
- Open status/settings

### Automation

- Start/end hooks
- Environment passed to hooks
- Timeout and failure behavior
- Presets for media pause, notification silencing, and locking

### Omarchy

- Enable/position bar widget
- Use Omarchy Shell overlay or native fallback
- Theme synchronization
- Lock integration
- Indicator integration
- Notification silencing behavior

### Privacy and diagnostics

- Live sensor/evidence display
- Exactly what is stored
- History retention and deletion
- Export sanitized diagnostics
- Optional adapters and their permissions

## Bar-panel boundary

The Omarchy bar popup should expose only:

- Next break
- Current routine/state
- Current suppression reason
- Take break now
- Pause/resume choices
- Today’s basic outcomes
- Open Settings

All configuration belongs in the full settings window. This follows the stronger third-party Omarchy plugin patterns: concise bar state, focused popup, separate complex configuration.

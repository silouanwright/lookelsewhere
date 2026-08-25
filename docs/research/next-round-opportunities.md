# Next-Round Product Opportunities

This is a decision brief, not a committed roadmap. It combines the LookAway
audit, eye-health evidence, current LookElsewhere implementation, Wayland
constraints, and the principle that interruption quality beats feature count.

## Decision criteria

Prioritize work that:

1. makes the timer more trustworthy;
2. prevents an interruption at the wrong moment;
3. helps the user understand or correct a decision;
4. improves the eye-break habit without increasing screen attention;
5. is demonstrably reliable on Omarchy and Wayland;
6. preserves local privacy and low idle resource use.

## Recommended sequence

### P0: Reversible natural-break handling

Implemented: meaningful away intervals now resume or reset the session, briefly
explain the decision with Undo, and persist the correction record. Deterministic
coverage includes idle/suspend-style gaps, recovery, and
manual pause. Lock integration and hostile wall-clock changes remain explicit
follow-up validation work.

This directly addresses the morning long-break failure and builds trust in the
state model.

### P0: Session statistics without surveillance

Add only the statistics that help tune break behavior:

- active screen time today;
- completed, snoozed, skipped, delayed, and naturally satisfied breaks;
- current and longest uninterrupted session;
- median completed session length;
- short versus long breaks;
- detector delay reasons in aggregate, without titles or content.

Do not add website tracking, app-content tracking, or a judgmental score.

### P1: Detector correction and exclusions

- explain the active detector in the panel and bar;
- allow application exclusions for microphone/video heuristics;
- distinguish foreground video from background audio where the platform can;
- warn when a keep-awake inhibitor prevents away detection;
- provide a correction action when a detector is wrong;
- retain cooldown and maximum-delay boundaries.

### P1: Planned breaks

Support fixed-time lunch, walk, and shutdown breaks only with the complete rule
set:

- selected weekdays, time, duration, name, and enabled state;
- independent relationship to Office Hours;
- no overlap;
- collision suppression with interval breaks;
- partial or complete credit for away time;
- grace after protected activity;
- ignored rather than skipped when too late to be useful;
- correct behavior across midnight and timezone changes.

### P1: Brief customizable break guidance

- separate short-break and long-break message pools;
- optional random message selection;
- independent title and subtitle visibility;
- a few concise defaults such as look far, blink slowly, or stand and move;
- no instruction carousel that keeps the user reading.

### P1: Accessibility completion

- increased-contrast behavior across every Omarchy theme;
- selection and state cues that do not rely only on color;
- screen-reader announcements for warning, break start, break completion, and
  enforcement state;
- logical focus restoration after overlays and settings editors;
- reduced motion and reduced transparency verification.

### P2: Automation and on-demand breaks

- start/end hooks with explicit commands and documented security boundaries;
- pause and restore MPRIS playback without starting media that was already
  paused;
- arbitrary-duration on-demand breaks;
- CLI commands for short, long, and custom breaks;
- temporary pause with an explicit duration.

### P2: Additional wellness modalities

Blink, posture, and sit/stand reminders can share scheduling infrastructure,
but they should remain independent routines with their own cadence and quiet
surfaces. Add them only after natural-break handling and statistics are trusted.

## Explicit non-priorities

- cloning LookAway's visual identity;
- Screen Score or other gamification without demonstrated value;
- website or browser-history collection;
- mobile sync before the local product is mature;
- animated backgrounds ahead of state correctness;
- a large exercise library displayed during a screen break;
- medical diagnosis or disease-prevention claims;
- complex machine-learning classification before reversible simple rules have
  been exhausted.

## Questions to answer before implementation

- What away-duration bands should resume, reset, or satisfy a break?
- Which observable signals can improve that decision without invasive input
  monitoring?
- How long should the correction action remain available?
- What is a “session” for statistics, and how does a natural break close one?
- Which statistics change a user decision rather than merely filling a chart?
- What exact collision window should planned breaks use?
- Which detector exclusions can be implemented reliably with current Hyprland,
  MPRIS, PipeWire, and Omarchy APIs?
- Which accessibility preferences are exposed by Omarchy today?

## Acceptance bar

A feature is ready when its success, ambiguity, and failure states are visible;
its keyboard and accessibility paths work; it survives restart and suspend; it
has deterministic state tests; and its documentation says what it cannot know.

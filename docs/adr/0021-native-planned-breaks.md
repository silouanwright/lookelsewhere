# ADR 0021: Coordinate Native Planned Breaks in the Existing Scheduler

- Status: Accepted
- Date: 2026-08-27

## Context

Interval eye breaks answer “how long have I actively used the screen?” Fixed
lunch, walk, and shutdown routines answer “what part of the day do I intend to
protect?” A calendar can eventually supply candidate times, but it cannot own
collision, away credit, protection, snoozing, persistence, or break outcomes.

Planned routines also expose state-machine edge cases that a separate alarm
timer would handle badly: Office Hours, regular breaks due nearby, protected
activity, idle time spanning the target, shell restart, suspend, midnight, and
timezone changes.

## Decision

Store a bounded array of native planned routines in the existing Omarchy plugin
settings. Each routine has a stable ID, name, local start minute, duration,
selected weekdays, and enabled state. Support at most eight routines and reject
same-day overlap.

Calculate recurrence from local wall-clock time, but route a selected occurrence
through the existing semantic scheduler and interruption surfaces. Persist only
the active occurrence and a bounded set of handled occurrence keys. Do not
persist a week of future timestamps.

Planned occurrences:

- run independently of Office Hours and interval active-time accumulation;
- respect global disable, manual pause, protected context, natural-pause policy,
  cooldown, and maximum delay;
- use the configured progressive warning before their target time;
- count qualifying idle time from the target toward their duration;
- offer only the remaining duration after partial away time;
- complete silently when away time satisfies the full duration;
- suppress an interval break within a ten-minute radius without changing the
  short/long-break streak;
- remain recoverable for the greater of thirty minutes or twice their duration,
  capped at two hours, then become ignored rather than skipped; and
- may always be skipped for that occurrence, while snoozing consumes the shared
  snooze budget.

An occurrence remains attached to its local starting date when it crosses
midnight. Future occurrences are recalculated after clock or timezone changes;
an already active occurrence retains its persisted identity and deadlines.

## Alternatives

- Calendar-first scheduling: rejected because it adds accounts, permissions,
  private event data, provider failures, and recurrence complexity without
  removing the need for an internal coordinator.
- Independent QML alarms: rejected because they would race the interval state
  machine and shell reloads.
- One scalar lunch setting: rejected because the requirement is a small
  collection of named recurring routines, not one hard-coded use case.
- Unlimited routines: rejected because plugin settings, overlap validation, and
  persisted handled keys need an explicit bound.

## Consequences

The state snapshot gains explicit routine identity and handled-occurrence data.
Completion and skip logic must distinguish interval and planned outcomes so a
planned break does not mutate long-break cadence. The settings UI needs a
keyboard-complete routine list and editor rather than exposing raw JSON.

Calendar integration, if added later, produces routine definitions for this
same coordinator. It does not replace it.

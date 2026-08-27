# Planned Breaks Findings

## Preliminary thesis

Planned breaks should be native recurring routines owned by LookElsewhere, not
calendar events. They must enter the same explicit scheduler as interval eye
breaks so collision, protection, away credit, persistence, and statistics have
one authoritative decision path.

## Verified precedent

LookAway documents that planned breaks recur at a local time on selected
weekdays; have independent names, durations, icons, and enabled state; ignore
Office Hours and interval-focused screen time; suppress nearby regular breaks;
share protected-context judgment; credit idle or locked time; offer only the
remaining duration after partial away time; and become Start Now, Snooze, or
Skip Today choices when picked up late. Overlapping routines are rejected.

The public documentation does not publish the suppression radius, grace
duration, or late-expiry threshold. Those numbers must therefore be explicit
LookElsewhere policy rather than implied compatibility.

Sources:

- https://lookaway.com/docs/planned-breaks/
- https://lookaway.com/blog/2026/06/22/lookaway-22-introducing-planned-breaks/

## LookElsewhere policy decisions

- Persist routine definitions in Omarchy's existing plugin entry as a bounded
  JSON array. Do not create a second settings store.
- Support at most eight routines. Each has a stable ID, name, local start
  minute, duration, selected weekdays, and enabled state.
- Use local wall-clock recurrence. An occurrence key combines routine ID and
  local starting date, so crossing midnight remains attached to its start day.
- Planned occurrences ignore Office Hours but respect global disable, manual
  pause, protected context, natural-pause gating, and maximum smart delay.
- Begin the normal warning window before the planned time. Protection may defer
  presentation without rewriting the original target.
- Use a ten-minute interval coalescing radius. Reset interval accumulation only
  when its due moment is within that radius; never change the long-break streak.
- Count idle time beginning at the target. Full duration completes silently;
  partial duration reduces the offered break to the remainder.
- Keep a late occurrence available for the greater of thirty minutes or twice
  its duration, capped at two hours. Then mark it ignored, not skipped.
- A planned occurrence may always be skipped for the day, including Hardcore.
  Snoozing still consumes the shared snooze budget.
- Reject same-day overlaps during configuration rather than guessing how to
  merge two named routines.
- Recompute future occurrences after timezone or clock changes. Persist only
  active and handled occurrence identity, not future weekly timestamps.

## Required decisions

- Routine configuration schema and safe bounds
- Local weekday/time recurrence semantics
- Relationship to Office Hours
- Collision and coalescing with interval and other planned breaks
- Away-time credit and late/missed behavior
- Protected-context grace and maximum delay
- Timezone, clock-change, suspend, and restart recovery
- User-facing warning, overlay, bar, panel, and statistics language

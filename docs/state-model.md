# State Model

## Primary states

```text
Disabled
  ↕
Paused
  ↕
Working → DueSoon → WaitingForPause → Warning → FinalCountdown → Breaking → Working
                         ↘ ProtectedContext ↗
                         ↘ Postponed ───────↗
                         ↘ Suppressed/Recovered
```

A planned occurrence joins the same warning and break path. When it is late but
still actionable, `PlannedReady` holds it until the user starts, snoozes, or
skips it for that day. Planned outcomes do not advance the ordinary long-break
cadence.

The persisted model records semantic state and timestamps. UI surfaces derive presentation from the snapshot; they do not invent independent timers.

## Core transitions

- **Working → DueSoon:** remaining active-use time approaches the warning threshold.
- **Working/DueSoon → ProtectedContext:** the warning threshold arrives while high-confidence protected context is active; the original due time remains the maximum-delay anchor.
- **Warning/FinalCountdown → ProtectedContext:** newly appearing high-confidence context withdraws an upcoming interruption before the break begins.
- **ProtectedContext → WaitingForPause:** context ends; start cooldown and seek a natural pause.
- **WaitingForPause → Warning:** natural pause appears, cooldown expires, or maximum delay is reached.
- **Warning → FinalCountdown:** warning grace expires or the user requests immediate start.
- **Warning → Postponed:** policy permits the selected postponement and budget remains.
- **FinalCountdown → Breaking:** countdown reaches zero.
- **Breaking → Working:** duration completes or the permitted completion action is used.
- **Any active state → Paused:** explicit user pause or outside office hours where configured.
- **Scheduled occurrence → Warning/FinalCountdown:** a planned routine reaches
  its local time, independent of Office Hours.
- **Protected planned occurrence → PlannedReady:** its protection or grace
  ends after the scheduled time; away time is credited against its duration.
- **Any state → recovered equivalent:** shell restart, suspend/resume, or clock change causes re-evaluation from timestamps and current evidence.

## Active-use accounting

- Count time only while the user is considered actively using the desktop.
- Idle periods do not accrue focus time.
- Returning after 5–59 minutes away resumes the existing focus session. Returning
  after 60 minutes or more starts a fresh session and resets the short/long-break
  cadence. LookElsewhere briefly explains either decision with an Undo action.
  Manual pause is never reclassified automatically.
- Short ambiguous idle may receive partial credit or ask for classification only after the MVP if a nonannoying design is proven.
- Protected context continues active-use accumulation while delaying the warning and interruption.

## Private statistics

- Count active screen time only while the scheduler considers the user active.
- A completed break or a one-hour natural-away reset closes the current focus
  session. Skipping a break does not, because the uninterrupted screen session
  continued.
- Daily summaries include completed short and long breaks, snoozes, skips,
  longest session, median completed-session length, and recent session outcomes.
- Midnight archives the local day while preserving an uninterrupted session
  that crosses the boundary.
- Retain at most seven previous days and twelve completed sessions per day so
  the bounded state document cannot grow indefinitely.
- Store no application names, window titles, URLs, media metadata, keystrokes,
  screenshots, or audio.

## Recovery invariants

- Reloading Omarchy Shell must not silently grant or erase a break.
- Suspend time is not active-use time.
- Wall-clock rollback/forward must not produce negative or enormous intervals.
- A missed warning while the shell was absent is reconciled against office hours, idle duration, current context, and maximum delay.
- Only one break session and one interactive action authority exist across outputs.

## Precedence

1. Disabled or explicit pause
2. Active break
3. Planned occurrence
4. Outside the ordinary active-use schedule
5. Final countdown/warning already presented
6. Protected context and cooldown
7. Due state and natural-pause policy
8. Normal working state

The feasibility prototype must turn these rules into pure transition tests before visual implementation is considered authoritative.

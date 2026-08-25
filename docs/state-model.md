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

The persisted model records semantic state and timestamps. UI surfaces derive presentation from the snapshot; they do not invent independent timers.

## Core transitions

- **Working → DueSoon:** remaining active-use time crosses the warning threshold.
- **DueSoon → ProtectedContext:** the break becomes due while high-confidence protected context is active.
- **ProtectedContext → WaitingForPause:** context ends; start cooldown and seek a natural pause.
- **WaitingForPause → Warning:** natural pause appears, cooldown expires, or maximum delay is reached.
- **Warning → FinalCountdown:** warning grace expires or the user requests immediate start.
- **Warning → Postponed:** policy permits the selected postponement and budget remains.
- **FinalCountdown → Breaking:** countdown reaches zero.
- **Breaking → Working:** duration completes or the permitted completion action is used.
- **Any active state → Paused:** explicit user pause or outside office hours where configured.
- **Any state → recovered equivalent:** shell restart, suspend/resume, or clock change causes re-evaluation from timestamps and current evidence.

## Active-use accounting

- Count time only while the user is considered actively using the desktop.
- Idle periods do not accrue focus time.
- A sufficiently long idle period may satisfy some or all of a pending break according to explicit thresholds.
- Returning after one hour without active use starts a fresh work session:
  the focus interval, long-break cadence, and snooze cycle reset while lifetime
  statistics and an explicit manual pause remain intact.
- Short ambiguous idle may receive partial credit or ask for classification only after the MVP if a nonannoying design is proven.
- Protected context may continue active-use accumulation while delaying interruption.

## Recovery invariants

- Reloading Omarchy Shell must not silently grant or erase a break.
- Suspend time is not active-use time.
- Wall-clock rollback/forward must not produce negative or enormous intervals.
- A missed warning while the shell was absent is reconciled against office hours, idle duration, current context, and maximum delay.
- Only one break session and one interactive action authority exist across outputs.

## Precedence

1. Disabled or explicit pause
2. Outside active schedule
3. Active break
4. Final countdown/warning already presented
5. Protected context and cooldown
6. Due state and natural-pause policy
7. Normal working state

The feasibility prototype must turn these rules into pure transition tests before visual implementation is considered authoritative.

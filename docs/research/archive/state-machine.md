# Runtime State Machine

## Top-level states

```text
BOOTSTRAPPING
  → WORKING
  → PAUSED
  → SUSPENDED
  → LOCKED

WORKING
  → DUE_SOON
  → PAUSED / SUSPENDED / LOCKED

DUE_SOON
  → WAITING_FOR_PAUSE
  → BREAKING
  → POSTPONED
  → SUPPRESSED

WAITING_FOR_PAUSE
  → BREAKING             natural pause or overdue deadline
  → POSTPONED
  → SUPPRESSED            protected context appeared

SUPPRESSED
  → WAITING_FOR_PAUSE     context cleared; grace remains
  → BREAKING              context cleared and overdue policy says start
  → POSTPONED             context cleared and catch-up policy postpones

BREAKING
  → RECOVERING            break completed or ended legitimately
  → WORKING               explicit skip
  → LOCKED                locked enforcement

RECOVERING
  → WORKING               cooldown complete and routine clocks reconciled
```

`PAUSED`, `SUSPENDED`, and `LOCKED` preserve enough prior state to resume through a reconciliation function rather than blindly returning to the prior state.

## Invariants

1. At most one break owns the overlay at a time.
2. All timing uses monotonic time while the process is running.
3. Wall-clock time is used only for planned schedules and work-hour boundaries.
4. A long break may satisfy overlapping short routines according to configuration.
5. A daemon restart reconstructs state from durable deadlines and an event journal.
6. A shell/UI restart never changes scheduler state.
7. Every suppression has a reason and expiry/re-evaluation trigger.
8. Missed routines are coalesced; a backlog never produces a burst of consecutive overlays.

## Transition details

### BOOTSTRAPPING

Load configuration, durable scheduler state, last clean shutdown marker, current clock, lock/session state, active monitors, Hyprland snapshot, and current context evidence. Reconcile before showing any UI.

Never display a break immediately solely because the daemon started late. Apply the configured missed-break policy.

### WORKING

Accumulate active-use time only while the user is not idle, locked, suspended, manually paused, or in a context configured to stop accumulation. Some protected contexts may continue accumulation while merely suppressing presentation.

### DUE_SOON

Emit a heads-up with start-now and postpone actions. If the user is already idle long enough to satisfy the routine, mark it completed without displaying an overlay.

### WAITING_FOR_PAUSE

Observe a short idle threshold such as 3–8 seconds. Start the break at a natural pause. Continue showing only a subtle countdown. Escalate at `maximum_overdue`.

### SUPPRESSED

Do not conflate suppression with pause:

- **Pause:** stop routine accumulation and deadlines.
- **Suppress:** allow routine to become due/overdue, but withhold disruptive presentation.

On context clear, apply one of `start`, `grace`, `postpone`, or `consider_satisfied`.

### BREAKING

Create one surface per selected output. Monitor changes recreate only affected surfaces. Keyboard ownership and skip policy derive from enforcement level. The daemon owns the countdown; surfaces are views.

### RECOVERING

Record the outcome, coalesce other due routines, schedule the next cycle, and apply a short notification-free cooldown.

## Edge cases

### Suspend during work

Persist state on `PrepareForSleep(true)`. On resume, do not count suspended duration as active work. Re-evaluate planned breaks against missed-break policy.

### Suspend during a break

Default: consider the break satisfied if suspended for at least the routine duration; otherwise resume or complete according to policy.

### Lock during a break

Treat lock duration as break time. Never put a break overlay above the lock screen. Reconcile after unlock.

### Monitor hotplug during a break

Create/remove overlay surfaces without restarting the break or resetting its timer.

### Hyprland restart

Disconnect adapter, retain scheduler state, mark compositor evidence stale, and reconnect with backoff. Reconcile from JSON snapshots before accepting new events.

### Omarchy Shell restart

No scheduler impact. If the plugin-owned overlay disappears, start the native fallback overlay after a short grace period.

### Daemon crash/restart

Recover from durable state. Never duplicate a completion record. If the prior state was BREAKING, use elapsed wall/monotonic reconciliation and default to a non-disruptive recovery notification.

### Clock or timezone change

Active-use timers remain monotonic. Recalculate future planned occurrences. Do not replay occurrences that moved into the past unless the explicit catch-up window includes them.

### Multiple routines due together

Rank by priority and combine compatible routines. One five-minute movement break can satisfy a nearby twenty-second visual break; the inverse is not true.

### Media starts during warning/grace

Re-evaluate policy. A high-confidence protected context moves to SUPPRESSED. Low-confidence media shows an unobtrusive “delay while playing?” action rather than silently disappearing.

### Protected context ends with an overdue break

Do not show the break immediately. Enter a configurable post-activity cooldown, explain that the break remains overdue, then wait for the next natural pause or maximum-overdue deadline.

### Return from ambiguous idle duration

If the away interval lies near a satisfaction/reset threshold and the application cannot infer whether it was restorative, ask whether to continue, satisfy the current routine, or reset the cycle. Offer to remember the choice for comparable durations.

### Partial idle credit for a long or planned break

Subtract qualifying away time from the occurrence duration. If the full duration was satisfied, complete silently. Otherwise offer the remainder instead of restarting the full break.

### User starts a break manually

Select the requested routine or a generic break. Reconcile scheduled routines upon completion based on satisfaction rules.

## Event journal

Store compact events only:

```text
timestamp, routine_id, event_type, duration, reason_code
```

Do not store window titles, URLs, media metadata, audio/video data, keystroke counts, or raw PipeWire graphs.

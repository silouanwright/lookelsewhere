# ADR 0020: Use One Countdown Presentation Clock

- Status: Accepted
- Date: 2026-08-25

## Context

The scheduler correctly derives remaining time from timestamps, but QML's
event loop can stall under load. No presentation component can render the
seconds that elapsed while the shared shell process produced no frames.
Replaying every missed value afterward makes the clock visibly accelerate and
extends a brief system stall into a longer product defect.

## Decision

Keep scheduler timestamps authoritative and derive each visible clock from one
total-seconds value. Animate only an ordinary one-second decrement. After a
missed sample, immediately snap to the current authoritative value without
replaying intermediate seconds.

## Alternatives

- Increase scheduler polling: rejected because it adds permanent model work
  without fixing an event-loop stall.
- Replay missed seconds: rejected because it cannot reconstruct frames that
  were never rendered and creates a visible fast-forward afterward.
- Show only static text: rejected because the rolling treatment is an intentional
  part of the product experience.

## Consequences

The scheduler and visible clock return to the correct wall-clock value as soon
as the event loop recovers. Ordinary ticks retain the rolling treatment;
multi-second changes and resets are immediate and do not race to catch up.

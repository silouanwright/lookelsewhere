# ADR 0020: Use One Countdown Presentation Clock

- Status: Accepted
- Date: 2026-08-25

## Context

The scheduler correctly derives remaining time from timestamps, but QML's
event loop can miss a one-second sample under load. Independent minute and
second catch-up components cannot interpret a missed minute boundary: a sample
change from `01:00` to `00:58` looks like an ordinary `00` to `58` reset and
drops `00:59`.

## Decision

Keep scheduler timestamps authoritative, but give every visible clock one
presentation queue measured in total seconds. Derive minutes and seconds only
after selecting the next displayed total. When a visible sample is missed,
present each intermediate second in order.

## Alternatives

- Increase scheduler polling: rejected because it adds permanent model work
  without fixing an event-loop stall.
- Animate minute and second fields independently: rejected because rollover
  destroys the information needed to recover a missed second.
- Show only static text: rejected because the rolling treatment is an intentional
  part of the product experience.

## Consequences

The scheduler remains wall-clock correct while the presentation may briefly
catch up after a stall. A compositor that produces no frame cannot display an
intermediate value during that frozen interval, but the next rendered sequence
does not silently discard it.

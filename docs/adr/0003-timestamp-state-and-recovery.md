# ADR 0003: Persist Timestamps and Reconstruct State

- Status: Accepted
- Date: 2026-08-22

## Context

In-memory decrementing timers lose truth during shell reload, suspend, process absence, and clock changes.

## Decision

Persist versioned semantic state and timestamps atomically. Reconstruct remaining active-use, cooldown, postponement, warning, and break state from current monotonic/wall-clock evidence rather than persisting a ticking counter.

## Alternatives

- Memory-only timers: rejected as unreliable.
- Per-second state-file writes: rejected for unnecessary IO and still-ambiguous recovery.
- Immediate daemon: deferred by ADR 0001.

## Consequences

Clock discontinuity and corrupt-state behavior require tests. Persisted schemas need versioning and non-destructive recovery.

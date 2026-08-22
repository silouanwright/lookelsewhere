# ADR 0004: Centralize Behavior in an Explicit State Machine

- Status: Accepted
- Date: 2026-08-22

## Context

Idle, protected context, cooldown, natural pauses, warnings, postponement, breaks, schedules, and recovery produce conflicting transitions when scattered through UI bindings.

## Decision

Represent product behavior as pure events and transitions over a single semantic state snapshot. UI derives from the state and issues commands; it does not own independent policy.

## Alternatives

- Independent QML timers per surface: rejected due to race and reload risks.
- Boolean flag collection without precedence: rejected as difficult to reason about.

## Consequences

The state engine and precedence rules must be tested before UI screenshots are considered behavioral proof.

# ADR 0008: Use Progressive Interruption Surfaces

- Status: Accepted
- Date: 2026-08-22

## Context

Ordinary notifications are easy to miss; immediate fullscreen interruption is unnecessarily abrupt. LookAway demonstrated an effective staged pattern.

## Decision

Use bar state, a top-centered actionable warning, a compact final countdown chip, and then the break overlay. Reinterpret the pattern with Omarchy-native visuals and independent copy.

## Alternatives

- Notification-only: rejected as too weak.
- Immediate overlay: rejected as too disruptive.
- Persistent large warning: rejected as visually noisy.

## Consequences

Transitions, focus, stable geometry, bar offsets, reduced motion, and maximum delay require runtime validation.

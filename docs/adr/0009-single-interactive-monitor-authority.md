# ADR 0009: Use One Interactive Authority Across Outputs

- Status: Accepted
- Date: 2026-08-22

## Context

A break may cover several monitors, but multiple independently actionable overlays create duplicate commands and inconsistent focus.

## Decision

Render passive break presentation on configured outputs while assigning actions and exclusive focus to exactly one selected output, normally the focused output at break start with a primary-output fallback.

## Alternatives

- Interactive controls on every monitor: rejected due to race and ambiguity.
- Overlay only one monitor: rejected as ineffective for multi-monitor attention.

## Consequences

Monitor hotplug and focus changes must not reset the break or transfer authority unpredictably.

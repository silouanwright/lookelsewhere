# ADR 0007: Default to Balanced Enforcement

- Status: Accepted
- Date: 2026-08-22

## Context

Easy dismissal makes reminders ineffective, while coercive lockout creates risk and hostility.

## Decision

Offer Gentle, Balanced, and Focused presets. Balanced is the default: postponement is available but bounded, and skipping becomes available only under explicit policy. Focused always retains a documented emergency exit.

## Alternatives

- Gentle-only: rejected as too easy to habituate away.
- Unskippable default: rejected as unsafe and paternalistic.

## Consequences

The UI must explain exact consequences and remaining postponement budget. Stronger behavior cannot be enabled accidentally.

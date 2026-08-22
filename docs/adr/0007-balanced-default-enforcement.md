# ADR 0007: Default to Balanced Enforcement

- Status: Accepted
- Date: 2026-08-22

## Context

Easy dismissal makes reminders ineffective, while an unskippable mode must be
an explicit choice rather than the default.

## Decision

Offer Gentle, Balanced, and Focused presets. Balanced is the default:
postponement is available but bounded. Focused is an explicit unskippable
choice: once its full-screen break begins, neither pointer, keyboard, nor IPC
can end it before the timer completes.

## Alternatives

- Gentle-only: rejected as too easy to habituate away.
- Unskippable default: rejected as too strong for an implicit default.

## Consequences

The UI and configuration contract must explain exact consequences and
remaining postponement budget. Focused cannot be enabled accidentally; users
who select it accept that an active break must run to completion.

# ADR 0007: Default to Balanced Enforcement

- Status: Accepted
- Date: 2026-08-22

## Context

Easy dismissal makes reminders ineffective, while an unskippable mode must be
an explicit choice rather than the default.

## Decision

Offer Casual, Balanced, and Hardcore presets. Balanced is the default:
postponement is available but bounded. Hardcore is an explicit unskippable
choice: once its full-screen break begins, none of LookElsewhere's pointer,
keyboard, or IPC actions can end it before the timer completes.

## Alternatives

- Casual-only: rejected as too easy to habituate away.
- Unskippable default: rejected as too strong for an implicit default.

## Consequences

The UI and configuration contract must explain exact consequences and
remaining postponement budget. Hardcore cannot be enabled accidentally; users
who select it accept that an active break must run to completion.

Hardcore is product enforcement, not a security boundary. It does not attempt
to block compositor shortcuts, virtual terminals, process termination, shell
restart, or other operating-system escape paths.

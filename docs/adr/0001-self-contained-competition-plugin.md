# ADR 0001: Ship a Self-Contained Competition Plugin

- Status: Accepted
- Date: 2026-08-22

## Context

A daemon would provide stronger process independence, but the competition rewards an immediately installable Omarchy plugin and the marketplace installer does not run setup hooks.

## Decision

Ship the competition MVP as one self-contained Quickshell plugin. Keep presentation dependent on an explicit state snapshot/command boundary so a daemon can replace the in-process engine later.

## Alternatives

- Separate Rust daemon now: rejected for installation friction and schedule risk.
- UI-only plugin over an existing timer: rejected because interruption policy is the differentiator.

## Consequences

We must prove persistence and recovery across shell reload. If that proof fails, this ADR must be superseded rather than masking the failure.

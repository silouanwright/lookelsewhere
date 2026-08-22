# ADR 0005: Treat Smart Context as Confidence-Weighted Evidence

- Status: Accepted
- Date: 2026-08-22

## Context

Fullscreen, MPRIS, PipeWire, process identity, and dictation signals reveal different pieces of context and vary by application. No universal Linux meeting-state API exists.

## Decision

Normalize detectors into coarse evidence with category, confidence, recency, and availability. Policy combines evidence, user rules, cooldown, and maximum delay. Explanations expose categories, not private metadata.

## Alternatives

- One-signal meeting detection: rejected as too error-prone.
- Mandatory app extensions: rejected as a baseline dependency.
- Hyprland modification: rejected because application semantics do not belong in the compositor.

## Consequences

Defaults must degrade conservatively and visibly. Screen-sharing support remains conditional on a reliable signal.

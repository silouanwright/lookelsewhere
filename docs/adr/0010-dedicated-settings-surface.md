# ADR 0010: Keep Deep Settings Out of the Bar Popup

- Status: Superseded by ADR 0013
- Date: 2026-08-22

## Context

Routines, context policy, enforcement, experience, privacy, and diagnostics exceed a compact bar popup. Installed plugins show that dense dashboards quickly become difficult to scan.

## Decision

Keep the quick panel to status and frequent actions. Use a dedicated settings surface with intent-based navigation and progressive disclosure. Prototype it in Quickshell first, but permit a later native application if accessibility or window behavior requires one.

## Alternatives

- All settings in popup: rejected.
- Configuration file only: rejected for a polished end-user product.

## Consequences

The competition cut may ship a smaller settings surface, but every exposed setting must work and deep configuration must not leak back into the popup.

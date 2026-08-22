# ADR 0002: Use Quickshell and Omarchy Native Surfaces

- Status: Accepted
- Date: 2026-08-22

## Context

Omarchy Shell and its plugin system are built with Quickshell/QML. First-party components already solve theme, bar anchoring, layer-shell, focus, IPC, scaling, and common controls.

## Decision

Implement the bar, panel, warning, chip, overlay, and initial settings spike in Quickshell using installed `qs.Ui` and `qs.Commons` primitives wherever suitable.

## Alternatives

- GTK/Qt standalone UI: rejected for the contest because it weakens native integration.
- Custom QML chrome: rejected because it would drift across Omarchy themes.

## Consequences

Component APIs must be re-inspected against the installed Omarchy version. A dedicated native settings application remains possible if Quickshell accessibility or window behavior proves inadequate.

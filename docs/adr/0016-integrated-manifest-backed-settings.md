# ADR 0016: Add Integrated Manifest-Backed Settings Pages

- Status: Accepted
- Date: 2026-08-24

## Context

ADR 0013 kept the competition MVP config-first to protect the core scheduler
and overlay work. Once those surfaces were stable, the number of supported
settings made CLI-only discovery unnecessarily difficult.

## Decision

Provide categorized settings pages inside the anchored plugin panel. Controls
write through Omarchy's persistence API, while `manifest.json` remains the
machine-enforced contract and Omarchy's `shell.json` remains the authoritative
store. The panel does not maintain a separate configuration file or model.

Keep frequent actions on the main panel page. Settings use progressive
disclosure, scrolling, visible keyboard focus, arrow navigation, Tab traversal,
Enter and Space activation, and Escape back-navigation.

## Consequences

Configuration is discoverable without sacrificing scriptability or creating a
second source of truth. The plugin owns more QML and accessibility behavior,
which is contained in `Views/SettingsPage.qml` and the Qmlpack-managed reusable
controls under `vendor/qmlpack/oma-ui-kit/Ui`.

ADR 0013 remains the record of the earlier MVP boundary and is superseded by
this decision.

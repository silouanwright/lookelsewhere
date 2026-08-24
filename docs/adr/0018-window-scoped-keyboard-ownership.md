# ADR 0018: Scope Panel Shortcuts to the Popup Window

- Status: Accepted
- Date: 2026-08-24

## Context

LookElsewhere is keyboard-first, but its panel shares one Quickshell process
with every Omarchy surface. Application-scoped shortcuts can keep intercepting
keys after another shell panel receives focus. Shortcut objects outside the
popup item tree may also have no usable window association and fail entirely.

## Decision

Place mnemonic shortcuts inside the anchored `KeyboardPanel` item tree and use
`Qt.WindowShortcut`. The popup owns shortcut activation only while it owns
keyboard focus. Another Omarchy panel taking focus disables LookElsewhere's
mnemonics immediately.

Keep ordered arrow navigation, Tab and reverse Tab, Enter and Space activation,
Escape behavior, visible focus, and shortcut badges driven by the same panel
control model. Global invocation remains an explicit user-configured Omarchy
binding rather than an application-scoped QML shortcut.

## Consequences

Panel commands work without leaking into other shell surfaces. Transient popup
lifecycle and focus ownership remain part of keyboard correctness and require
regression checks whenever panel structure changes.

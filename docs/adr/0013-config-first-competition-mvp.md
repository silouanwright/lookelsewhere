# ADR 0013: Use Manifest-Backed Configuration for the Competition MVP

- Status: Superseded by ADR 0016
- Date: 2026-08-22

## Context

Omarchy plugins declare defaults and a typed schema in `manifest.json`. Per-widget values live in `~/.config/omarchy/shell.json` and can be changed through `omarchy bar set`. The installed shell does not automatically render that schema as a graphical settings window.

A bespoke Quickshell settings surface duplicates persistence and validation concerns, increases the accessibility and visual-QA burden, and is not necessary to demonstrate the core break experience. The competition plan explicitly prioritizes the scheduler, smart context, warning, break overlay, and reliable packaging.

## Decision

Ship the competition MVP with manifest-backed configuration and document supported `omarchy bar set` examples. Keep the anchored panel focused on current status and frequent actions. Do not ship a bespoke settings window in the MVP.

The manifest schema is the public configuration contract and the Omarchy shell configuration is the source of truth. A graphical client may be reconsidered after the MVP based on user demand; it must consume the same contract rather than introduce a second settings model.

## Alternatives

- Dedicated Quickshell settings surface: deferred because it adds substantial non-core scope.
- Put all controls in the anchored popup: rejected because it would make the frequent-action surface dense.
- Require hand-editing JSON: supported but not required; the documented CLI is safer.

## Consequences

Configuration remains native, inspectable, scriptable, and small in implementation cost. Discoverability is lower than a graphical client, so defaults must be excellent and the README must document common changes. ADR 0010's dedicated-surface requirement is superseded for the competition MVP.

# Accessibility Contract

LookElsewhere is designed to remain operable without a pointer and legible
without relying on color alone.

## Interaction

- The bar widget, panel actions, settings categories, toggles, dropdowns,
  number fields, text fields, planned-break weekdays, and full-screen actions
  expose names, roles, actions, and relevant selected or checked state.
- Disabled actions remain visible for context but cannot be invoked by pointer,
  keyboard, or an accessibility press action.
- Dropdown choices expose individual names and selection state. Closing a
  dropdown restores its exact trigger; closing another editor preserves a
  named accessible setting cursor instead of moving to an anonymous proxy.
- Warning and natural-break surfaces use on-demand layer-shell keyboard focus;
  the full-screen break uses exclusive focus only while the break is active.
- Warning, final-countdown, break-start, and break-completion transitions emit
  accessibility announcements. Countdown labels change at coarse milestones
  rather than producing accessibility events every second.

## Visual preferences

Reduce Motion disables rolling countdowns, reveal motion, blur animation, and
panel timer crossfades. Reduce Transparency removes panel patterns, blur, and
translucent full-screen break backdrops.

Semantic content keeps native font and control sizes. A constrained full-screen
surface scrolls instead of shrinking its guidance, countdown, and actions. The
panel grows to fit its action row up to the available screen width.

## Contrast evidence

The shared secondary-text role blends 82% of the theme's popup text over its
popup background. The representative theme check on 2026-08-29 measured:

| Theme | Primary text | Secondary text |
|---|---:|---:|
| Catppuccin Latte | 7.06:1 | 4.55:1 |
| Tokyo Night | 8.10:1 | 5.87:1 |

Both secondary values meet WCAG 2 contrast for ordinary text. The same role is
used throughout the production panel and warning surface; the showcase uses
the production formula so documentation captures remain representative.

## Verification

Run:

```bash
/usr/lib/qt6/bin/qmltestrunner -input tests/qml \
  -import /usr/share/omarchy/shell -import . -platform offscreen
./tests/check-panel-shortcuts.sh
./tests/check-accessibility.sh
./tests/check-live-plugin.sh
./tests/check-live-reliability.sh
```

Then inspect the installed plugin with keyboard-only navigation, Reduce Motion,
Reduce Transparency, Catppuccin Latte, and Tokyo Night. `qmllint` must be run
from `/usr/lib/qt6/bin/qmllint`; its unresolved `qs.*` diagnostics are an
Omarchy runtime-root limitation rather than proof of a plugin type error.

## Remaining platform limitation

On August 29, 2026, the installed Omarchy/Quickshell runtime was restarted with
Qt accessibility forced on. AT-SPI discovered the Quickshell applications, but
each application exported zero child objects. The plugin's QML names, roles,
states, and actions therefore cannot yet be traversed by Orca in this runtime.

This is not something a plugin can repair inside its QML tree. It needs
Quickshell or its Qt window integration to export that tree through AT-SPI.
Until then, static semantics, keyboard-only operation, contrast, reduced motion,
and reduced transparency remain verified, while end-to-end screen-reader support
must be described as blocked by the host runtime.

# Design Feedback Reconciliation

This ledger converts Silouan Wright's live design direction into verifiable
implementation requirements. A request is not complete merely because a
similar treatment exists: source evidence and, for visual behavior, an
installed-runtime check are required.

## Bar widget

| Direction | Implementation evidence | Verification |
|---|---|---|
| Keep the panel anchored to the LookElsewhere bar item | `BarWidget.panelLoader`, `Panel.anchorItem`, and `KeyboardPanel.centerOnBar: false` | Exercised at every bar edge |
| Offer icon, time, or icon-and-time without hover | Manifest `displayMode`; `BarWidget.showIcon/showTime` | Exercised horizontally; vertical bars intentionally use the icon |
| Keep icon/time spacing stable as digits change | Natural-width `barContent` centered inside a content-derived `fixedWidth` | Live captures at one- and two-digit minute values |
| Center the active underline under icon and time together | The host `WidgetButton` owns the full content-derived width | Live-verified after width correction |
| Show away/idle suspension compactly in the bar | `BarWidget.compactTime` renders `Idle`; idle uses the pause glyph | Deterministic idle fixture and real resume verified |
| Round minutes down, then show seconds below one minute | `Model.formatBarDuration` floors minutes and uses second precision below 60 seconds | Boundary regression tests |
| Keep bar and interrupting-surface seconds synchronized | Sub-minute bar and overlay both use ceiling-rounded seconds | Boundary regression tests and live warning comparison |

## Anchored quick panel

| Direction | Implementation evidence | Verification |
|---|---|---|
| Use a narrow, portrait composition instead of a wide status card | `KeyboardPanel` target width of 260 theme-space units and vertical hierarchy | Live-verified |
| Remove the progress bar and explanatory filler | No progress component or generic active-time notice in `Views/Panel.qml` | Source-inspected and live-verified |
| Center the supplied break/bed symbol above the heading | `Ui/BedIcon.qml` plus centered icon item | Live-verified across the active theme |
| Use “Break starts in,” directly over and close to the timer; switch it to “LookElsewhere is paused” during idle | Centered state-aware heading with negative bottom margin | Live-verified; working wording regression-tested |
| Show a large native-looking `MM:SS` clock | Two rolling numbers and one colon at display scale | Live-verified |
| Make colon spacing follow the active font's metrics | `TextMetrics` removes only the colon's unused side bearings | Live-verified with the active Omarchy font |
| Roll only digits that change | `RollingNumber` delegates independently to `RollingDigit` | Live-verified at `20 → 19` and `19 → 18` |
| Put Break now, +1m, +5m, and +15m on one line | One `RowLayout` action rail with compact labels | Live-verified |
| Give timer actions stronger type, less vertical padding, and slightly rounder corners | `WeightedButton`: Bold, four-unit vertical padding, theme-derived increased radius | Live-verified on 2026-08-22 |
| Keep buttons shrink-wrapped to their labels | Explicit implicit size from active label metrics and native padding | Source-inspected and live-verified |
| Provide history and settings icons in the upper right | Header actions switch between timer, history, and options pages | Live-verified |
| Put Pause/Resume, Stop, and settings-file navigation under the gear | Options actions and managed Omarchy processes | Source-inspected; Pause/Resume exercised live |
| Keep the shelved graphical settings work | `docs/research/archive/SettingsView.prototype.qml` | Preserved in repository |

## Warning and break surfaces

| Direction | Implementation evidence | Verification |
|---|---|---|
| Keep warnings top-centered rather than attached to the bar | `Overlay.warningCard/finalChip` use top anchors and horizontal centering | Live-verified |
| Enter warning during the final focus seconds, not after zero | `Model.observe` starts warning from remaining focus time | Regression-tested and timer-driven flow verified |
| Use a final countdown before the break overlay | Explicit Warning → Final → Breaking states | Regression-tested and live-verified |
| Use a calm, blurred full-screen treatment | Theme lock background plus staged content motion, opacity, and `MultiEffect` blur | Iteratively approved live |
| Let the backdrop arrive before slightly staggered content | Separate backdrop, opacity, motion, and blur timelines | Iteratively approved live |
| Keep vertical content travel restrained and ease near the end | 24 theme-space-unit offset with `OutCubic` motion | Iteratively approved live |
| Animate the lock-screen countdown per digit | `RollingNumber` in the break surface | Live-verified |
| Make the skip affordance more opaque against the overlay | Theme-derived hover fill used as its resting background | Live-verified |
| Preserve reduced-motion behavior | Reveal state resolves immediately when `reducedMotion` is enabled | Source-inspected and fixture-verified |

## Product behavior tied to the interface

| Direction | Implementation evidence | Verification |
|---|---|---|
| Snoozing is in the MVP and bounded | +1m/+5m/+15m actions, cycle budget, enforcement policy, persisted totals | Model-tested and live action verified |
| Do not present “Pause 1h” as a primary action | No one-hour timer-page action; indefinite Pause/Resume lives under options | Source-inspected and live-verified |
| Smart idle suspension must be visible | Bar changes to `Paused`; tooltip explains the away state | Fixture-verified |
| Preserve Omarchy theming instead of copying macOS chrome | Live surfaces use `Color`, `Style`, `Border`, and native shell primitives | Osaka Jade and Catppuccin Latte exercised |

## Still requiring physical evidence

- A second real output is required to prove monitor hotplug and interactive
  authority during an already-active break. The delegate lifecycle defect is
  fixed in source, but one connected output cannot prove the physical path.
- Large accessibility text scaling still needs a dedicated capture matrix.

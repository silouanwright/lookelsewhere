# QML Code Review Report

**Scope:** runtime QML and model tests at the competition MVP boundary  
**Files reviewed:** `BarWidget.qml`, `Panel.qml`, `Overlay.qml`, `Service.qml`, rolling-number components, and QML tests
**Method:** deterministic Qt/QML lint, system `qmllint`, and six semantic passes covering bindings, layout, lifecycle, delegates, states, and performance

The final long-break and overlay refinements through commit `bebc87b` received
a diff-scoped six-pass review. All six passes reported zero confirmed findings
and zero investigation targets. The deterministic linter introduced no new
actionable changed-line finding; standalone `qmllint` again reported only the
documented runtime-root import-resolution limitations. The exact QML test suite
now passes 49 checks with zero failures, including configurable shortcut
validation, long-break cadence, and policy migration.

## Confirmed findings and disposition

| Finding | Confidence | Disposition |
|---|---:|---|
| `Service.state` shadowed `QQuickItem.state`, risking failed natural warning bindings | 100 | Fixed by renaming the service property to `phase`; live timer-driven flow verified warning, final chip, and break |
| A monitor delegate created during an active break could remain invisible while intercepting input | 94 | Fixed by reconciling the reveal on delegate completion through the approved animation path |
| Demo teardown could restore stale settings after an Omarchy config change | 87 | Fixed by updating the saved authoritative config whenever settings change during demo mode |
| Capped quick-panel height could make lower content unreachable | 88 | Fixed with a bounded vertical Flickable and native scrollbar |
| Warning and final surfaces could overflow narrow/scaled outputs | 84–86 | Fixed with responsive warning rows, wrapped copy, capped chip width, and elision |
| Detector polling caused process churn and dictation polling incorrectly waited for a never-ending stream to exit | 96 | Fixed with event-driven fullscreen state and a managed line-by-line Omarchy dictation stream |
| Every scheduler tick deep-cloned state through JSON and renormalized stable config | 86 | Fixed with an explicit structured snapshot copy and normalized-config fast path |
| State loading raced asynchronous state-directory creation | 88 | Fixed by exposing the state file only after successful directory creation and blocking persistence on failure |
| Hidden panel and per-output countdowns continuously created rolling animations | 93 | Fixed with an explicit animation-active contract that snaps hidden surfaces and animates only visible countdowns |
| The floating toolbar could overlap centered page content at larger scales | 91 | Fixed with symmetric content clearance, preserving the approved visual spacing and optical centering |

## Additional hardening

- Delegate capture now uses explicit bound component semantics in both the
  per-output overlay and rolling-number repeater.
- The four countdown actions remain on one line and scale down only when their
  natural width would exceed the popup.
- Full-screen break content scales within short logical outputs while remaining
  unchanged at normal sizes.
- Component tests cover inactive snapping, active animation, reduced motion,
  digit-boundary changes, minimum digit count, sequential recovery from a
  small missed countdown sample, and immediate handling of a true reset. The
  complete suite passes 49 tests with zero failures.

## Environmental lint limitations

Standalone `qmllint` cannot fully resolve Omarchy's runtime-root `qs.Commons` and `qs.Ui` imports, so unresolved custom-type and associated unqualified-name messages are not treated as defects without runtime corroboration. The installed shell was restarted after each relevant change and its journal inspected for plugin warnings.

## Remaining investigation targets

- Profile lazy construction of secondary popup pages only if measurements show
  the current small eager object tree has material cost.

The process-lifetime investigation is closed: the actual keyboard-accessible
**Stop Look Elsewhere** control was invoked in the installed shell. Its child
process completed after the panel and plugin objects were unloaded, the plugin
became disabled, no orphan remained, and re-enabling restored the persisted
non-demo schedule without a Look Elsewhere error or coredump.

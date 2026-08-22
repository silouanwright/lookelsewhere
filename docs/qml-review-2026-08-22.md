# QML Code Review Report

**Scope:** runtime QML and model tests at the competition MVP boundary  
**Files reviewed:** `BarWidget.qml`, `Panel.qml`, `Overlay.qml`, `Service.qml`, `tests/qml/tst_Model.qml`  
**Method:** deterministic Qt/QML lint, system `qmllint`, and six semantic passes covering bindings, layout, lifecycle, delegates, states, and performance

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

## Environmental lint limitations

Standalone `qmllint` cannot fully resolve Omarchy's runtime-root `qs.Commons` and `qs.Ui` imports, so unresolved custom-type and associated unqualified-name messages are not treated as defects without runtime corroboration. The installed shell was restarted after each relevant change and its journal inspected for plugin warnings.

## Remaining verification

- Automated component-level keyboard/focus tests
- Large text scale and narrow-output capture matrix
- Monitor hotplug during an active break
- Full top/bottom/left/right bar-position visual matrix

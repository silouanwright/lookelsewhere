# Architecture Decision Records

ADRs use `Accepted`, `Proposed`, or `Superseded` status. Accepted decisions govern implementation until explicitly superseded.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-self-contained-competition-plugin.md) | Ship a self-contained competition plugin | Accepted |
| [0002](0002-quickshell-native-surfaces.md) | Use Quickshell and Omarchy native surfaces | Accepted |
| [0003](0003-timestamp-state-and-recovery.md) | Persist timestamps and reconstruct state | Accepted |
| [0004](0004-explicit-state-machine.md) | Centralize behavior in an explicit state machine | Accepted |
| [0005](0005-confidence-based-smart-context.md) | Treat context detectors as confidence-weighted evidence | Accepted |
| [0006](0006-data-minimization.md) | Minimize and localize observed data | Accepted |
| [0007](0007-balanced-default-enforcement.md) | Default to Balanced enforcement | Accepted |
| [0008](0008-progressive-interruption-surfaces.md) | Use progressive interruption surfaces | Accepted |
| [0009](0009-single-interactive-monitor-authority.md) | Allow one interactive authority across outputs | Accepted |
| [0010](0010-dedicated-settings-surface.md) | Keep deep settings out of the bar popup | Superseded by 0013 |
| [0011](0011-deterministic-demo-and-fixtures.md) | Make every state deterministically stageable | Accepted |
| [0012](0012-public-plugin-packaging.md) | Package as a public, dependency-light marketplace plugin | Accepted |
| [0013](0013-config-first-competition-mvp.md) | Use manifest-backed configuration for the competition MVP | Superseded by 0016 |
| [0014](0014-wayland-natural-pause-gate.md) | Gate due breaks on a short Wayland input pause | Accepted |
| [0015](0015-explicit-protected-applications.md) | Protect explicitly configured applications | Accepted |
| [0016](0016-integrated-manifest-backed-settings.md) | Add integrated manifest-backed settings pages | Accepted |
| [0017](0017-bound-data-before-qml.md) | Bound and shape replaceable data before QML | Accepted |
| [0018](0018-window-scoped-keyboard-ownership.md) | Scope panel shortcuts to the popup window | Accepted |
| [0019](0019-reviewable-source-packages.md) | Manage extracted source through reviewable packages | Accepted |
| [0020](0020-one-countdown-presentation-clock.md) | Use one total-seconds countdown presentation clock | Accepted |
| [0021](0021-native-planned-breaks.md) | Coordinate native planned breaks in the existing scheduler | Accepted |
| [0022](0022-optional-sundown-steam-pause.md) | Use optional Sundown evidence to pause during Steam games | Accepted |

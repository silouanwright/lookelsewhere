# Verification Strategy

## Layers

### Pure policy tests

Test time accounting, state transitions, enforcement budgets, detector precedence, cooldown, maximum delay, office hours, overnight schedules, partial idle credit, and recovery from timestamp snapshots without UI.

### QML/component tests

Test formatting, state-to-copy mapping, action availability, focus order, overlay authority selection, and model bindings with fixture snapshots.

### Manifest/static checks

- `omarchy plugin validate <repo>`
- `qmllint` with installed Omarchy Shell imports
- JSON schema/version checks for configuration and state fixtures
- No symlinks or undeclared entry points in the distributable repository

### Runtime integration

- Discover, enable, open, close, disable, and re-enable
- Quickshell rescan and shell restart
- Idle/active transitions
- MPRIS playback start/stop
- Microphone/communication start/stop
- Fullscreen enter/leave
- Dictation start/stop
- Suspend/resume and clock discontinuity
- Monitor add/remove and focus change
- Top/bottom/left/right bar positions where relevant

### Visual QA

Capture every material state at native scale:

- Bar working, due, paused, protected, unavailable
- Quick panel normal, protected, empty-history, error/recovery
- Warning, focused warning if supported, final chip
- Break overlay on single and multiple monitors
- Casual/Balanced/Hardcore action differences
- Dark and contrasting light/high-contrast theme
- Rounded and sharp-corner treatment
- Reduced motion

Review alignment, gutters, baselines, focus, contrast, wrapping, clipping, scroll behavior, and geometry stability.

## Deterministic fixtures

Expose development-only or explicitly guarded IPC commands/snapshot fixtures for every state. Demo mode must:

- contain synthetic labels only;
- avoid real process/media/meeting inspection;
- advance without real waiting;
- leave persistent user state untouched;
- reset cleanly after capture.

## Acceptance gates

1. Feasibility gate: each required detector and surface has a measured result and fallback.
2. Model gate: transition/recovery tests pass.
3. Interaction gate: complete demo flow works keyboard-only.
4. Resilience gate: shell reload, suspend, and monitor changes preserve invariants.
5. Visual gate: reference captures pass the plugin-design rubric.
6. Packaging gate: clean install/remove in a fresh test location.
7. Submission gate: public artifacts and marketplace metadata match the verified commit.

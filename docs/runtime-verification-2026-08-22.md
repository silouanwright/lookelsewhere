# Runtime Verification — 2026-08-22

Environment: Omarchy 4.0.0, Quickshell 0.3-compatible shell APIs, Hyprland,
one focused `HDMI-A-2` output at 3840×2160 with scale 2.

## Installed scheduler

- The installed clone was updated through `omarchy plugin update` and the
  shell was restarted in a separate step.
- `omarchy-shell look-elsewhere status` returned a real `working` state after
  restart, with demo mode off and no recovery warning.
- `omarchy-shell look-elsewhere diagnostics` reported fullscreen, dictation,
  MPRIS, PipeWire, idle, and sound capabilities available, with persistence
  unblocked.
- The timer-driven `flow` fixture traversed warning, final countdown, and
  breaking through the real one-second scheduler rather than direct fixture
  replacement.

## Keyboard and accessibility

- Opening the anchored panel through IPC establishes its keyboard surface.
- Tab and Backtab traverse `Break now`, the bounded snooze actions, history,
  and options controls in both directions.
- Escape dismisses the panel without invoking either action.
- Focused enforcement's documented `Ctrl+Shift+Esc` emergency exit returned
  the service to `working` during a live break fixture.
- The shell journal contained no Look Elsewhere QML errors during the checks.

## Bar geometry and lifecycle

- The bar and anchored panel were exercised at top, bottom, left, and right.
- Horizontal bars showed the configured icon-and-time presentation.
- Vertical bars collapsed to the icon and retained an inward-opening anchored
  panel, avoiding an unreadable rotated or crowded countdown.
- The original top position was restored after the matrix.
- Rapid bar reconstruction exposed an obsolete panel IPC handler. IPC
  ownership was moved from transient `Panel.qml` instances to the resident
  `BarWidget.qml`, matching current first-party plugin practice. Repeating the
  bottom/top reconstruction then opened the correct panel with no duplicate
  handler warning.

## Theme behavior

- Osaka Jade (dark) and Catppuccin Latte (light) were exercised.
- The bar widget, warning surface, actions, break overlay, countdown, and
  blurred desktop treatment remained legible in both.
- The original Osaka Jade theme was restored after the matrix.

## Package lifecycle

- A clean temporary home cloned the repository through the real
  `omarchy plugin add file:///… --yes` path and passed the installed manifest
  validator from the cloned directory.
- The same staged clone was removed through `omarchy plugin remove … --yes`,
  and its plugin directory no longer existed afterward.
- Omarchy's removal command consults the one shared running shell by plugin ID,
  even when `$HOME` points at a staging home. The isolated removal therefore
  unloaded the live instance; it was immediately re-enabled from the real home,
  retained its persisted working schedule, and produced no coredump. Future
  lifecycle staging should run with no user shell active or use a separately
  namespaced fixture ID.

## Corrupt-state recovery

- The running shell was stopped before the persisted snapshot was replaced
  with deliberately invalid JSON, preventing a race with the periodic writer.
- On restart, Look Elsewhere entered a safe default working state, exposed the
  recovery warning through status and the quick panel, set persistence blocked,
  logged the parse failure, and left the invalid source file unchanged.
- The exact pre-test snapshot was restored, including accumulated focus time
  and all outcome totals. A second shell restart loaded it with an empty
  recovery warning and normal persistence resumed.
- The test ended with demo mode off, the anchored panel showing the real
  countdown, and no coredump.

## Output hotplug during a break

- A transient Hyprland headless output was created while the real service was
  already in the breaking state, exercising delegate creation after the state
  transition rather than before it.
- The new `HEADLESS-1` output immediately received one Look Elsewhere layer and
  rendered the complete themed break surface; it did not become a transparent
  input-blocking window.
- The output was removed cleanly, the original display remained active, demo
  mode was cleared, and the service returned to its preserved working schedule
  without a coredump.

## Current limitations

- Only one physical output is connected. Compositor-level creation and removal
  during an active break is verified with a transient headless output, but
  physical multi-monitor focus handoff and mixed-scale presentation remain
  candidates for future hardware acceptance.

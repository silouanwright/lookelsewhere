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

## Current limitations

- Only one physical output is connected, so real output hotplug and
  cross-monitor action-authority acceptance remain unproven. The deterministic
  delegate lifecycle review and focused-output selection logic cover the code
  path but do not replace physical multi-monitor evidence.
- Corrupt-state preservation is implemented and fixture-tested visually; an
  isolated runtime parse/write acceptance test remains because the plugin's
  actual state path must never be destructively exercised for release QA.

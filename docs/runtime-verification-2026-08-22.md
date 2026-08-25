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
- An ordinary shell restart reproduced a 20-second countdown rollback with the
  previous 30-second checkpoint. The final five-second checkpoint bounds that
  visible rollback without counting suspend or idle time as active use.

## Live detector acceptance

- Chromium MPRIS playback was exercised both behind a fullscreen Steam game
  and while Chromium itself was focused. Background playback correctly emitted
  no evidence. Focused playback emitted `media` evidence at confidence `0.8`
  with the `Video` context label, and pausing cleared both on the next
  observation.

- The focused `steam_app_1868140` XWayland game produced high-confidence
  protected-application evidence and the subdued `Focus` bar status. Its
  fullscreen mode `2` was reconciled without continuous polling.
- A real Hyprland fullscreen transition produced `fullscreen` evidence at
  confidence `0.65` and cleared immediately on restore.
- Dictation and microphone input checks were blocked below LookElsewhere by the
  machine's unavailable audio input path. Voxtype logged an ALSA stream setup
  failure, while PipeWire reported no target input node.
- The detailed results and current accounting contract are recorded in
  [`detector-acceptance-2026-08-22.md`](detector-acceptance-2026-08-22.md).

## Final release media

- Root preview, quick panel, progressive warning, long-break still, and the
  23-second warning-to-break demo were recaptured from the final installed
  runtime on an empty workspace at native compositor scale.
- The stills were losslessly resized to 2048×1152 for repository delivery. The
  video is a silent 3840×2160 H.264 capture with cursor capture disabled.
- Frame inspection covered the warning, final chip, break reveal, active break,
  and clean return to the preserved real schedule. No private application
  content appears in the committed media.

## Typing protection

- The guarded `typing` fixture retained the real Wayland idle-notify signal but
  suppressed persistence and sounds.
- Repeated modifier-only input changed the bar to `Typing..` and held the
  warning deadline at exactly 10,000 ms.
- After input stopped, the two-second recent-input window released the hold.
  It intentionally exceeds one scheduler interval so sparse input cannot
  expire immediately before it is sampled.
- Clearing the fixture restored the exact real schedule with no recovery
  warning.

## Keyboard and accessibility

- Opening the anchored panel through IPC establishes its keyboard surface.
- Tab and Backtab traverse `Break now`, the bounded snooze actions, history,
  and options controls in both directions.
- With the panel open, `B`, `1`, `2`, `3`, `P`, `H`, `O`, and `Q` invoke the
  documented break, snooze, pause, page-navigation, and close actions. History,
  options, pause/resume, and close were exercised in the installed shell.
- Optional global binding examples use currently unclaimed `Super+Alt` chords;
  they remain opt-in so installation never overwrites a user's Hyprland keys.
- The installed panel's `1` mnemonic was exercised in both an ordinary
  working fixture and an active warning. During ordinary focus it added one
  minute while remaining in `working`; during the warning it entered the
  bounded one-minute postponed state. Clearing demo mode restored the exact
  real schedule.
- Manifest-backed custom shortcut values and conflict fallback pass model
  acceptance. Opening the native clock panel closed LookElsewhere through the
  shared bar-popout coordinator; LookElsewhere mnemonics then remained inactive.
- Escape dismisses the panel without invoking either action.
- The earlier Hardcore emergency-exit behavior was intentionally superseded.
  Installed Casual and Balanced fixtures accepted IPC skip immediately.
  Hardcore rejected IPC skip, Escape, and Ctrl+Escape while its countdown kept
  advancing, then returned to working only at natural completion. The disabled
  pointer action is guarded by the same `canSkipBreak` authority. Clearing the
  fixture restored the real non-demo schedule and Hardcore configuration.
- The shell journal contained no LookElsewhere QML errors during the checks.

## Rolling countdown continuity

- Countdown authority remains the persisted wall-clock deadline; presentation
  never extends or shortens a focus interval.
- If the QML event loop misses one or two displayed samples under load, the
  rolling number traverses the small gap in order instead of visibly jumping
  from (for example) `6` directly to `4`.
- Large changes, including fixture changes and schedule resets, snap to the new
  authoritative value rather than animating through stale seconds.
- Component acceptance covers both behaviors and the complete suite passes 52
  tests with zero failures.

## Break sounds

- The bundled CC0 Grand Piano K start and return cues were each played
  successfully through `canberra-gtk-play` at the configured app volume.
- Transition tests prove that scheduler and manual break entry select the start
  cue, natural completion selects the return cue, and unrelated transitions
  remain silent. Demo and restoration paths are explicitly suppressed.
- A lightweight timer runs only during a break and arms the return cue once in
  the final 25 milliseconds, keeping its onset aligned with visual dismissal. The
  state transition retains a guarded fallback without double-playing.
- The master switch, independent cue switches, 0–100 app volume, bundled
  defaults, and optional absolute or `~/` custom paths are manifest-backed.

## Bar geometry and lifecycle

- The bar and anchored panel were exercised at top, bottom, left, and right.
- Horizontal bars showed the configured icon-and-time presentation.
- Vertical bars collapsed to the icon and retained an inward-opening anchored
  panel, avoiding an unreadable rotated or crowded countdown.
- The original top position was restored after the matrix.
- Rapid bar reconstruction exposed an obsolete panel IPC handler. IPC
  ownership was moved from transient `Views/Panel.qml` instances to the resident
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
- The installed quick panel's real **Stop LookElsewhere** action was reached
  through keyboard navigation and invoked. The plugin became disabled, its IPC
  target disappeared, and the panel-owned process left no orphan even though
  its action unloaded the owning component.
- Re-enabling through `omarchy plugin enable` restored the widget immediately
  after `omarchy.tray`, recreated the IPC service, and loaded the preserved
  pre-demo break state. The break was then exited through the documented
  emergency action, leaving a real 20-minute working schedule with demo mode
  off, persistence unblocked, and no LookElsewhere error or coredump.

## Corrupt-state recovery

- The running shell was stopped before the persisted snapshot was replaced
  with deliberately invalid JSON, preventing a race with the periodic writer.
- On restart, LookElsewhere entered a safe default working state, exposed the
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
- The new `HEADLESS-1` output immediately received one LookElsewhere layer and
  rendered the complete themed break surface; it did not become a transparent
  input-blocking window.
- The output was removed cleanly, the original display remained active, demo
  mode was cleared, and the service returned to its preserved working schedule
  without a coredump.

## Constrained output

- A second transient output was configured through Hyprland's current Lua
  evaluation API at 800×600 logical pixels and focused for fixture capture.
- The top-centered warning remained within safe horizontal margins with
  readable wrapped copy and countdown; the full break surface remained
  centered, legible, and unclipped at the short output height.
- After both captures, demo mode was cleared and the output removed. The real
  schedule resumed, the physical output regained focus, and `hyprctl
  configerrors` remained empty.

## Current limitations

- Only one physical output is connected. Compositor-level creation, removal,
  800×600 constrained presentation, and creation during an active break are
  verified with transient headless outputs, but physical multi-monitor focus
  handoff and mixed-scale presentation remain candidates for future hardware
  acceptance.

# Product Roadmap

Updated August 29, 2026. This is the current priority list for LookElsewhere.
The README carries the public summary; research documents and completion
matrices preserve the evidence behind these decisions but do not supersede
this file.

## Ongoing acceptance

- Continue live verification with Steam games, Chromium
  video, calls, screen sharing, dictation, fullscreen applications, suspend,
  and mixed-monitor setups without overstating what Wayland can identify. This
  is a recurring release gate, not an unfinished feature.
- Keep keyboard navigation, light and dark themes,
  persistence recovery, bounded external input, and shell reload behavior under
  regression coverage.

## Recently shipped

- Optional Sundown integration that pauses active-time accounting during an
  actual Steam or Proton game, retains standalone window protection, expires
  stale evidence, and explains the active detector in Context and diagnostics.
- Optional, privacy-bounded Chromium integration for foreground playing video,
  muted video, paused/buffering transitions, and Picture-in-Picture, with
  Standard, Enhanced, and Unavailable status plus MPRIS/PipeWire fallback.
- **Countdown reliability:** wall-clock deadlines remain authoritative;
  ordinary ticks animate, missed samples snap current, and scheduler gap/work
  diagnostics plus a timer-driven live acceptance check expose real stalls.
- **Context acceptance harness:** every protected-context fixture now passes
  through the installed service and restores the exact real configuration.
- **Custom break guidance:** short and long breaks now have independently
  configurable titles and guidance in the Breaks settings tab.
- Native recurring planned breaks with weekday scheduling, protected-context
  grace, away-time credit, coalescing, snoozing, and Skip Today.
- Reversible fresh-session handling after meaningful time away.
- Private, chart-free daily statistics and bounded recent history.
- Privacy-safe PipeWire context for microphones, meetings, cameras, screen
  sharing, and explicit video roles.
- Focused-app protection with Steam defaults and an in-panel **Add current app**
  / **Remove current app** action.
- Compact bar explanations for active context, with cooldown and maximum-delay
  boundaries that prevent indefinite holds.
- Progressive warnings, long breaks, sounds, enforcement modes, office hours,
  deterministic demo states, and complete keyboard control.
- Named and stateful accessibility semantics, focus-preserving editors,
  non-color state cues, native-sized responsive content, reduced motion,
  reduced transparency, and verified light/dark contrast.

## Next

1. **Sound refinement:** a small set of optional cues, in-panel preview, and
   clearer custom-sound configuration.
2. **Host accessibility follow-through:** validate with Orca when Quickshell
   exports its QML child tree through AT-SPI; track this as an upstream platform
   dependency rather than duplicating semantics in the plugin.

## Later

- Narrow per-detector application exceptions when PipeWire or MPRIS
  classifications are demonstrably wrong.
- Optional start/end hooks and arbitrary-duration on-demand breaks.
- MPRIS pause-and-resume that never starts media which was already paused.
- Longer-term private trends only when they answer a useful question.
- Blink reminders and other independent wellness routines.
- Broader Quickshell and Wayland support, with a standalone scheduler only if
  the shell lifecycle becomes the wrong reliability boundary.

## Product constraints

- No telemetry, website history, window-title retention, screen capture, or
  audio recording.
- No detector claim that cannot be demonstrated on the supported stack.
- No gamified score or dashboard added merely to make the product look larger.
- No instruction-heavy break screen that keeps the user looking at the screen.
- Every feature must remain explainable, keyboard-accessible, and native to
  Omarchy.

# Findings: OmaRest Competitive Audit

## Thesis

OmaRest is a legitimate adjacent product, not a LookElsewhere clone. OmaRest
sets continuous-use limits for selected applications. LookElsewhere is a
system-wide eye-break scheduler that tries to choose a considerate moment to
interrupt. The products overlap at warnings and full-screen breaks, but their
core jobs are different.

## Where OmaRest is stronger

- First-class per-application rules: allowance, break duration, away-reset
  threshold, active days, and time windows.
- A deliberate override interaction: hold Space or the pointer action to end a
  break early, with an always-available emergency shortcut.
- A compact concept that is easy to explain as a focus boundary for chosen
  applications.
- Local daily usage totals by rule and explicit completed-versus-overridden
  outcomes.
- A deterministic Node test suite. All 41 checks passed at the audited commit.

## Where LookElsewhere is stronger

- System-wide eye-strain rhythm with short and long breaks, office hours,
  bounded snoozing, progressive warnings, and Casual/Balanced/Hardcore policy.
- Smart context from away time, focused applications, fullscreen state, MPRIS,
  PipeWire microphone/camera/screen-share roles, and Omarchy dictation.
- Natural-break credit and recurring planned breaks for lunch, prayer, walks,
  or shutdown routines.
- A deeper Omarchy-native surface: live themes, optional panel patterns,
  menubar states, full arrow-key navigation, configurable jump commands,
  sounds, and private chart-free statistics.
- A broader accessibility contract, including reduced transparency, contrast
  evidence, semantic controls, coarse timer announcements, and keyboard focus
  handling across transient surfaces.
- More defensive process and persistence boundaries. LookElsewhere shapes
  active-window evidence before QML and reads replaceable state through a
  descriptor-bound, no-follow, nonblocking, ownership-checked byte cap.

## Engineering comparison

OmaRest is smaller but substantially more monolithic: its `Panel.qml` is about
1,585 lines and the selected runtime/model/test surface is about 3,094 lines.
LookElsewhere's non-vendored QML/JS surface is about 7,221 lines, reflecting a
larger product and more separated views/components.

OmaRest persists both configuration and runtime state locally, caps retained
data, and writes atomically. Its read helper nevertheless checks a pathname
and then invokes `head` on it. That follows symlinks and can block on a FIFO or
other special file; it does not provide the descriptor-bound guarantees of
LookElsewhere's `bounded-read`. Its Hyprland fallback also retains a capped
whole `activewindow` response in QML and polls every five seconds, whereas
LookElsewhere producer-shapes the result and uses event-driven/debounced
reconciliation.

OmaRest has meaningful keyboard support and some accessibility semantics, most
notably on its break override and reduced-motion control. The code does not
show LookElsewhere's complete arrow-navigation/jump layer or similarly broad
screen-reader semantics.

## Product recommendation

Do not turn LookElsewhere into an app limiter merely because OmaRest exists.
The clearest idea worth borrowing later is an optional per-application rhythm
or budget for users who want stricter limits around a game, browser, or work
app. It should remain a separate advanced mode, not complicate the eye-strain
MVP.

The immediate lesson is positioning: describe LookElsewhere as the private,
context-aware Omarchy system for reducing eye strain, then make smart timing,
planned/natural breaks, and keyboard-native polish visibly concrete. OmaRest's
shorter conceptual pitch is a useful benchmark.

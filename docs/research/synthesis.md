# Research Synthesis

## Executive conclusion

There is room for a dedicated Omarchy/Wayland break coach, but visual polish alone is not sufficient differentiation. The product opportunity is **excellent interruption judgment, several calm recovery modalities over time, and first-class Omarchy integration**.

The strongest existing product insight is that users do not reject breaks because the timer lacks features; they reject them because the reminder arrives at a bad moment, loses context, provides poor control, or feels unreliable. LookElsewhere therefore treats timing policy, recovery behavior, and transparent context reasoning as core product design.

## How the idea evolved

The investigation began with night-light tooling on Hyprland/Omarchy and moved into LookAway-style screen breaks. Early questions included whether Linux already had an equivalent, whether a new application was justified, and whether it should be an Omarchy plugin or a standalone application with an Omarchy layer.

The first architectural conclusion favored a standalone daemon plus an optional Omarchy client because durable schedules and state should survive shell restarts. The competition later changed the delivery constraint: the initial submission should be a self-contained Quickshell plugin for frictionless installation, while keeping the state/UI boundary extractable into a daemon later.

## Competitive landscape

Products reviewed included LookAway, Sane Break, Workrave, RSIBreak, Stretchly, BreakTimer, and related eye-break utilities.

### What the category already does well

- Configurable work and break intervals
- Short and long break cadence
- Fullscreen or prominent break surfaces
- Work-hour schedules
- Snooze/skip policies
- Idle detection in varying quality
- Simple statistics and reminders
- Multiple break prompts or exercises in mature products

### Recurring weaknesses

- Blind wall-clock timing
- Poor meeting, video, presentation, or dictation awareness
- Timers that reset or drift after restart/suspend
- Binary “interrupt or suppress” logic without cooldown or natural-pause handling
- Little explanation for why a break moved
- Either trivial dismissal or coercive lockout
- Platform-native polish concentrated on macOS
- Linux interfaces that feel like standalone utilities rather than part of the desktop

### Adversarial conclusion

A generic 20-20-20 timer would not justify a new project. LookElsewhere must demonstrate materially better interruption timing and Omarchy integration in its first release. Dashboards, themes, streaks, exercise libraries, and AI coaching are not substitutes for this core.

See the preserved [competitive matrix](archive/competitive-matrix.md).

## What LookAway taught us

Public documentation, release posts, feature descriptions, and user-supplied screenshots were audited as competitive research—not as a visual template to clone.

### Progressive interruption

The reference warning uses two stages:

1. A top-centered action card with exact countdown, reassurance, `Start now`, and several postponement choices.
2. A smaller top-centered “Starting break in N” chip immediately before the break.

This is more deliberate than a normal desktop notification and less jarring than jumping straight to fullscreen. LookElsewhere adopts the progression but renders it with Omarchy tokens and its own information hierarchy.

### Settings clarity

The reference settings window uses categorized navigation, grouped rows, concise summaries, and visual enforcement cards. The useful lesson is information architecture, not macOS glass styling. Complex settings deserve a proper surface; the bar popup should remain focused on status and frequent actions.

### Small behaviors create perceived intelligence

The public audit uncovered many “do not annoy me” behaviors whose combined effect matters more than a marquee feature:

- Typing and dragging grace
- Post-meeting cooldown
- Partial idle credit
- Asking when idle classification is ambiguous
- Coalescing planned and regular breaks
- Overnight office hours
- Per-session and daily snooze budgets
- Early end after sufficient rest
- Session recovery after restart
- Natural-pause waiting with a maximum-delay escape valve

These edge cases were promoted ahead of analytics, gamification, website tracking, and decorative content.

See the [public audit](archive/lookaway-public-audit.md), [screenshot
observations](archive/lookaway-observations.md), and the
[LookAway documentation](https://lookaway.com/docs/). Third-party screenshots
used during local research are intentionally not redistributed.

## Detection feasibility

No required MVP signal belongs in a Hyprland fork. Existing desktop protocols and Omarchy/Quickshell services cover the foundation.

### Signal layers

| Signal | Source | Interpretation |
|---|---|---|
| User activity/idle | Wayland idle facilities / Quickshell | Reliable activity accounting; inhibitor semantics require care |
| Active app/fullscreen/workspace | Hyprland IPC / Quickshell Hyprland | Reliable compositor state, not semantic intent |
| Media playback | MPRIS | Strong when applications expose it; player metadata must be minimized |
| Microphone/communication activity | PipeWire/WirePlumber | Useful meeting evidence; roles and properties vary by application |
| Dictation | Omarchy indicators/local state | Strong on this desktop if the local contract remains stable |
| Camera/screen streams | PipeWire and portal-related evidence | Potentially useful but inconsistent; not a universal registry of other apps' portal sessions |
| Precise app semantics | Optional future adapters | Improves confidence but must not be required for basic operation |

### Policy conclusion

Detectors provide evidence, not truth. The policy engine should combine category, confidence, recency, user rules, cooldown, and a maximum delay. Application plugins may later improve precision, but meeting semantics do not belong in the compositor.

### Privacy conclusion

The implementation can inspect transient process/application identifiers where necessary, but should not persist or display window titles, URLs, media titles, meeting names, transcripts, audio, video, or screen content. Context explanations should use coarse categories.

The original environment probe confirmed Hyprland IPC, PipeWire, WirePlumber, MPRIS, and login/session facilities on the development machine. See [detection feasibility](archive/detection-feasibility.md) and the preserved probes.

## Omarchy and Quickshell findings

Omarchy Quattro is itself a long-running Quickshell shell with manifest-discovered plugins. Quickshell is therefore the native implementation layer, not an external UI toolkit bolted onto Omarchy.

### Reusable first-party infrastructure

The installed source contains:

- Theme-aware shared `Color`, `Style`, and `Border` systems
- `Panel`, `KeyboardPanel`, `PopupCard`, and bar widget lifecycle primitives
- Fullscreen `PanelWindow` and Wayland layer-shell patterns
- Exclusive and nonexclusive keyboard-focus examples
- Inhibitor-aware idle monitoring
- MPRIS/PipeWire media correlation
- Microphone-in-use observation
- Indicators for dictation, screen recording, DND, night light, and stay-awake
- Notifications, reminders, OSD, lock, background, and polkit surfaces
- IPC patterns for opening, closing, querying, and staging plugin behavior

### Installed third-party plugins

Six installed plugins were inspected in code and visually:

- System Monitor
- OmaFMail
- Omarchy Sensei
- 1Passchy
- Herdr Agents
- Voice Journal

The strongest recurring patterns were service/presentation separation, native token usage, fitted popup geometry, manifest configuration, IPC, state-aware refresh, and explicit empty/offline states. Common weaknesses included dense popup dashboards, bespoke styling that drifts from Omarchy, polling, and oversized monolithic QML files.

Voice Journal provided a detailed local worked example: it evolved toward native popup width and gutters, reactive state, live microphone feedback, in-panel playback, a durable Rust core, and explicit IPC. Its large panel file also demonstrated when a richer workflow needs decomposition or a larger surface.

See the [Omarchy plugin audit](archive/omarchy-plugin-audit.md) and [installed-plugin contact sheet](reference-screenshots/installed-plugin-contact-sheet.png).

## Design conclusions

### Surface progression

```text
bar state → native quick panel → top-center warning → final countdown chip → break overlay → quiet return
```

### Visual direction

- Quiet, warm, and spatially stable
- Inherit active Omarchy typography, palette, spacing, borders, radius, and control states
- One recognizable LookElsewhere symbol rather than a fixed brand skin
- One primary action per surface
- Hierarchy through spacing and type before nested cards
- Stable geometry during timer ticks
- Motion that explains transitions, with reduced-motion behavior
- No entertaining fullscreen spectacle that keeps the eyes on the display

### Surface responsibilities

- **Bar:** glanceable time/state and invocation
- **Quick panel:** current state, take-now/pause/reconnect, context explanation, small today summary, settings entry
- **Warning:** exact countdown and immediate/postpone choices
- **Final chip:** compact inevitable transition
- **Overlay:** calm instruction, remaining time, policy-appropriate exit
- **Settings:** routines, Smart Context, enforcement, experience, system/privacy; never compressed into the popup

### Accessibility

- Full keyboard operation and visible focus
- Predictable Escape behavior
- No reliance on color or pointer hover alone
- Configurable timing and postponement within policy
- Reduced-motion support
- Explicit opt-in strong enforcement with disclosed, unskippable consequences
- Exactly one interactive authority across multiple monitors

See the [design system](archive/design-system.md), [configuration specification](archive/configuration-spec.md), and [Omarchy MVP design](archive/omarchy-mvp-design.md).

## Configuration findings

Settings should use progressive disclosure:

- Start with editable presets.
- Organize by user intent, not implementation subsystem.
- Keep ordinary manifest settings bounded and simple.
- Use a dedicated settings surface for routines, detector policy, enforcement, history, privacy, automation, and diagnostics.
- Collapse confidence thresholds and other expert controls.
- Never expose a control before its behavior exists.

Recommended top-level settings areas are Overview, Breaks, Smart Context, Enforcement, Experience, and System/Privacy.

## Architecture evolution

### Earlier recommendation

A standalone daemon was originally preferred for scheduling, activity state, history, recovery, and cross-compositor evolution, with an Omarchy plugin as a thin native client.

### Competition decision

For the competition MVP, one-command installation and immediate judgeability outweigh early daemon extraction. The plugin will initially be self-contained, persist timestamps atomically, and recover state after shell reload. Presentation will still consume a clear state snapshot so the engine can move to a daemon later without redesigning the UI.

This is a delivery tradeoff, not a claim that Quickshell is always the ideal durable scheduler.

## Rejected or deferred directions

- **Clone LookAway visually:** rejected; use its interaction lessons with Omarchy identity.
- **Generic Pomodoro timer:** rejected as insufficiently differentiated.
- **Hyprland fork for meeting detection:** rejected; semantic context belongs above the compositor.
- **Mandatory app/browser plugins:** rejected for MVP; adapters are optional precision improvements.
- **Camera/content inference:** deferred for reliability and privacy.
- **Cloud/mobile sync:** deferred; unrelated to core interruption quality.
- **Website usage analytics:** rejected for MVP due to privacy and weak core value.
- **Gamification and health scoring:** deferred/rejected; may distort honest behavior.
- **Large exercise library:** deferred until content quality and safety can be reviewed.
- **Fixed branded glass theme:** rejected; must inherit Omarchy.
- **Deep settings in the bar popup:** rejected; use a proper settings surface.
- **External daemon in the contest cut:** deferred to protect installation and demonstration quality.

## Naming research

`GlanceAway` was rejected after discovering an active 2026 iPhone/Mac eye-break product with that exact name. `LookElsewhere` was selected because it describes the desired action, supports calm natural copy, and had no direct software/Omarchy collision found during the search. The team should still avoid implying affiliation with LookAway and maintain a clearly independent identity.

## Remaining validation questions

1. Which Quickshell idle primitive gives the most reliable active-use and inhibitor behavior in the installed Omarchy version?
2. Can PipeWire roles distinguish communication from ordinary capture consistently enough for default meeting delay?
3. What stable local contract should expose Omarchy dictation state?
4. Should overlays be owned by the resident service or declared as a separate manifest kind?
5. Can timestamp-based JSON recovery meet suspend, clock-change, and hot-reload invariants without a daemon?
6. Which settings-window shape provides strong keyboard accessibility and window management in Quickshell?
7. What warning focus policy works reliably without stealing focus during typing?
8. How should screen sharing degrade when no trustworthy system-wide signal exists?

These questions belong in focused executable spikes. They do not justify repeating the broad market or design research.

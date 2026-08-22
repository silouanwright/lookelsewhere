# LookAway Public Feature Audit

Audit of LookAway’s public documentation, release posts, product pages, and screenshots through 2026-08-22. This is a requirements study, not a mandate to reproduce every feature.

## Product lesson

LookAway’s strongest differentiation is accumulated interruption judgment. Many individually small rules combine to make the application tolerable over long-term use:

- Wait until typing or dragging stops.
- Detect and defer around calls, media, games, recording, and sharing.
- Apply a cooldown after protected activity ends.
- Distinguish partial idle time from a completed break.
- Ask the user when idle classification is ambiguous.
- Resume state after application restart.
- Coalesce planned and interval breaks.
- Replace “skip” with “end” when enough of a break has elapsed.
- Support overnight work schedules.
- Budget snoozes by day or session.

These behaviors are more important to the proposed product than recreating Liquid Glass, animated backgrounds, a numerical wellness score, or website statistics.

## Public feature inventory and disposition

| Feature observed | Our disposition | Reason |
|---|---|---|
| Focused active-use interval | **Core/MVP** | Fundamental scheduler input |
| Short and periodic long breaks | **Core/MVP** | Expected baseline; routine coordinator handles collisions |
| Work/office hours including overnight | **Core/MVP** | Important real schedule edge case |
| Advance warning with start/snooze choices | **Core/MVP** | Prevents abrupt interruption |
| Final countdown chip | **Core/MVP** | Clear progressive transition |
| Wait for typing to stop | **Core/MVP outcome** | Implement with natural-pause idle threshold rather than keylogging |
| Wait for drag to stop | **Research/M1** | Wayland does not expose global drag state portably; compositor support may help |
| Idle pause/reset/completion | **Core/MVP** | Major quality differentiator |
| Ask when idle interpretation is uncertain | **Core/MVP** | Honest ambiguity handling |
| Post-activity cooldown | **Core/MVP** | Prevents a break immediately after a call/video |
| Fullscreen/deep-focus app rules | **Core/MVP on Hyprland** | Strong compositor evidence and explicit user rules |
| Media playback detection | **Core/MVP heuristic** | MPRIS available; foreground/background policy required |
| Meeting detection | **M2 detector** | PipeWire microphone evidence plus app rules; false positives require correction UI |
| Screen recording/sharing detection | **M2 detector/adapters** | No universal observer API; use evidence and integrations |
| Fullscreen game detection | **M2 heuristic** | Combine fullscreen, app identity, media/game role, and explicit rules |
| Planned fixed-time breaks | **M1** | Valuable and state-machine-sensitive |
| Planned/regular break coalescing | **M1** | Prevents back-to-back interruptions |
| Partial away-time credit | **M1** | Particularly important for long planned breaks |
| Grace when a planned break is late | **M1** | Better than forcing a stale break |
| Casual/Balanced/Hardcore enforcement | **Core concept** | Rename to Gentle/Deliberate/Locked for clearer behavior |
| Daily and per-session snooze limits | **M1** | Useful adherence control without absolute blocking |
| Snooze from break screen | **M1** | Recovery path when warning was missed |
| Early “End Break” after sufficient rest | **M1** | Avoids classifying legitimate partial rest as a skip |
| Posture and blink reminders | **M1 routines** | Important alternate modality; independent cadence |
| Reminder size and position | **M1** | Needed for accessibility and multi-monitor ergonomics |
| Custom messages | **M1** | Low complexity, meaningful personalization |
| Custom backgrounds and gradients | **M2** | Polish after core correctness |
| Animated backgrounds | **Later/optional pack** | GPU/battery/reduced-motion concerns |
| Custom gentle sounds | **M1** | Sound quality affects perceived interruption |
| Start/end automations | **Core/M1** | Linux shell hooks and D-Bus are natural strengths |
| Pause music during break | **Built-in automation preset** | MPRIS makes this straightforward and reversible |
| Focus-mode integration | **M2** | Map to notification silencing, inhibitors, user profile, or external status |
| Calendar integration | **M2 adapter** | Use standard calendar sources/connectors where available; permission-sensitive |
| Global scripting commands | **Core/MVP API** | D-Bus plus CLI, broader than AppleScript |
| Keyboard shortcuts | **M1** | Hyprland bindings and portal/global shortcut paths |
| Quick status/control panel | **Core Omarchy plugin** | Natural bar-plugin experience |
| Overtime nudges | **M1** | Useful when a due break remains deferred or ignored |
| Resume prior session after restart | **Core/MVP invariant** | Reliability requirement |
| Total active screen time | **M1 history** | Simple local aggregate |
| Longest and median session | **M1 history** | Actionable without content surveillance |
| Break history/outcomes | **M1 history** | Needed to tune policies |
| Numerical Screen Score | **Defer/reconsider** | Can become judgmental/gamified; validate demand first |
| Per-application usage | **Later opt-in** | Privacy-sensitive and not necessary for break timing |
| Website/domain usage | **Non-goal initially** | Requires browser adapters/permissions and shifts product toward surveillance |
| iPhone/iPad synchronization | **Non-goal initially** | Large second-platform project |
| Lock-screen live countdown | **Omarchy opportunity, later** | Could integrate with Omarchy lock service if public extension surface exists |
| Custom on-demand break types | **M1** | Already natural within routine model |
| Advance skip | **Research** | Useful for known interruptions but risks habitual avoidance |

## Feature behaviors to add to the state model

### Idle classification

Idle intervals should result in one of:

- Too short: continue the active-use cycle.
- Enough for a short routine: satisfy it silently.
- Partially satisfies a long/planned routine: offer only the remainder.
- Long enough to reset the whole cycle: start fresh.
- Ambiguous near a threshold: ask on return, with a remembered preference option.

### Protected-context exit

When a meeting, video, recording, game, or focus rule clears:

1. Do not immediately show the overdue overlay.
2. Start a configurable cooldown.
3. Show a small explanation if a break remains overdue.
4. Wait for the next natural pause or maximum-overdue boundary.

### Planned-break collision

- A planned break suppresses compatible interval breaks in a configurable window.
- A longer break can satisfy a shorter routine, but not vice versa.
- Overlapping planned breaks are rejected or explicitly merged at configuration time.
- Planned occurrences crossing midnight remain attached to their starting day.

### Break dismissal vocabulary

- **Postpone:** move the occurrence; counts against the configured budget.
- **Skip:** abandon this occurrence; recorded as skipped.
- **End:** enough of the break elapsed to count as completed.
- **Complete silently:** idle/locked time satisfied the routine without an overlay.

## Linux/Omarchy advantages over LookAway

The proposed product can be stronger in several areas:

- Stable CLI and D-Bus API from the beginning.
- User-editable declarative routine configuration.
- Shell hooks and executable automation without AppleScript constraints.
- Explainable detector evidence rather than a single opaque Smart Pause switch.
- Compositor adapters with explicit capabilities.
- Omarchy bar, notification, indicator, lock, theme, and OSD integration.
- Local privacy controls and sanitized diagnostics.
- A core that can expand to other Wayland compositors.

## Public sources reviewed

- Documentation index: https://lookaway.com/docs/
- Setting up: https://lookaway.com/docs/setting-up/
- Smart Pause: https://lookaway.com/docs/high-engagement/
- Planned Breaks: https://lookaway.com/docs/planned-breaks/
- Stats: https://lookaway.com/docs/stats/
- Automations: https://lookaway.com/docs/automations/
- AppleScript commands: https://lookaway.com/docs/applescript/
- Office Hours: https://lookaway.com/docs/scheduling/
- LookAway 1.10: https://lookaway.com/blog/2025/02/13/lookaway-110-wellness-reminders-and-more/
- LookAway 1.11: https://lookaway.com/blog/2025/03/19/lookaway-111-automations-focus-filters-and-more/
- LookAway 1.12: https://lookaway.com/blog/2025/04/30/lookaway-112-smarter-and-less-interruptive/
- LookAway 1.13: https://lookaway.com/blog/2025/06/09/lookaway-113-calendar-integration-overtime-nudges-and-more/
- LookAway 2.0: https://lookaway.com/blog/2026/04/07/lookaway-20-screen-score-liquid-glass-and-more/
- LookAway 2.2: https://lookaway.com/blog/2026/06/22/lookaway-22-introducing-planned-breaks/
- LookAway 2.4: https://lookaway.com/blog/2026/08/07/lookaway-24-live-activities-on-mac-and-iphone/

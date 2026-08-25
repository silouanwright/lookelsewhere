# LookAway Public Feature Audit

Audit of LookAway’s public documentation, product-release posts, changelog, product pages, and screenshots through 2026-08-25. This is a requirements study, not a mandate to reproduce every feature.

The site sitemap was used as the coverage index. Every product-behavior page in
the documentation and every feature-release post was reviewed. Licensing,
installation, comparison/SEO, and general eye-health articles were inventoried
but excluded when they did not describe application behavior.

## Product lesson

LookAway’s strongest differentiation is accumulated interruption judgment. Many individually small rules combine to make the application tolerable over long-term use:

- Wait until typing or dragging stops.
- Detect and defer around calls, media, games, recording, and sharing.
- Apply a cooldown after protected activity ends.
- Distinguish partial idle time from a completed break.
- Infer whether idle time was a real break, explain the decision unobtrusively,
  and let the user undo it.
- Resume state after application restart.
- Coalesce planned and interval breaks.
- Replace “skip” with “end” when enough of a break has elapsed.
- Support overnight work schedules.
- Budget snoozes by day or session.

These behaviors are more important to the proposed product than recreating Liquid Glass, animated backgrounds, a numerical wellness score, or website statistics.

## Highest-leverage gaps for LookElsewhere

1. **Reversible natural-break handling.** We now reset a session after one hour
   away, but LookAway 2.3's stronger idea is the correction loop: decide quietly,
   explain briefly, and let the user switch between restart and resume.
2. **Useful statistics without surveillance.** Add daily active time, breaks,
   longest uninterrupted session, median session length, and outcomes before
   considering per-app, website, or Screen Score tracking.
3. **Planned breaks.** Fixed-time lunch/walk/shutdown breaks are meaningfully
   different from interval breaks and need collision, lateness, away-credit,
   and midnight rules from the start.
4. **Detector correction and exclusions.** Every heuristic needs visible reason,
   app/device exclusions, cooldown, and a way to correct a false positive.
5. **Accessibility beyond keyboard input.** Preserve reduced motion, then add
   increased-contrast and non-color-only selection behavior across themes.

Custom backgrounds, more sounds, wellness content, mobile sync, website usage,
and scoring remain lower leverage than these five behaviors.

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
| Quiet idle classification with undo | **M1** | LookAway replaced its blocking question with an automatic decision, toast, and reversible menu action |
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
| Hide snooze-budget messages | **M1 polish** | Avoid dead or noisy copy when no limit exists or the user opts out |
| Snooze from break screen | **M1** | Recovery path when warning was missed |
| Early “End Break” after sufficient rest | **M1** | Avoids classifying legitimate partial rest as a skip |
| Posture and blink reminders | **M1 routines** | Important alternate modality; independent cadence |
| Reminder size and position | **M1** | Needed for accessibility and multi-monitor ergonomics |
| Custom messages | **M1** | Low complexity, meaningful personalization |
| Separate randomized short/long messages | **M1** | Small extension to existing custom title/subtitle support |
| Independently hide title/subtitle | **M1 polish** | Useful with custom backgrounds and minimalist break screens |
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
| Arbitrary-duration on-demand break | **M1** | Useful after finishing a task or before a known commitment |
| Advance skip | **Research** | Useful for known interruptions but risks habitual avoidance |
| Per-detector exclusions | **M1** | Prevent music apps, editors, virtual microphones, and similar false positives |
| Keep-awake inhibitor warning | **M1 diagnostics** | Explains why away detection may not activate |
| Full localization and locale-aware durations | **Later** | Important for broad distribution; requires more than translated strings |
| Increased-contrast and no-color-only states | **Core accessibility** | Must accompany themes, patterns, hints, and reduced motion |

## Feature behaviors to add to the state model

### Idle classification

Idle intervals should result in one of:

- Too short: continue the active-use cycle.
- Enough for a short routine: satisfy it silently.
- Partially satisfies a long/planned routine: offer only the remainder.
- Long enough to reset the whole cycle: start fresh.
- Ambiguous near a threshold: make the best quiet decision, show a brief
  auto-dismissing explanation with Undo, and retain the same correction in the
  panel. A blocking question is the older, more disruptive design.

The public documentation says LookAway may pause or reset after idle time, but
does not publish a fixed threshold. Version 2.3 instead describes a multi-signal
classification. LookElsewhere must therefore treat its current one-hour reset
as its own conservative policy, not claimed LookAway parity.

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

### Additional edge rules worth preserving

- Planned breaks run independently of Office Hours and do not change the
  regular-break streak.
- Planned and interval breaks do not stack; a nearby interval break is
  suppressed.
- A partly completed planned break offers only the remainder on return; a fully
  completed one ends silently.
- A planned break picked up too late asks to start, snooze, or skip for the day;
  if too little useful time remains, it is marked ignored rather than skipped.
- Smart-context exit gets a grace period rather than triggering immediately.
- Video detection needs foreground/background policy and explicit exclusions
  for music, video-editing, and other false-positive applications.
- Typing and dictation delay only the imminent interruption and must have a
  reliable release path so the scheduler cannot remain stuck.
- A snoozed warning must reappear at the warning threshold, not silently jump
  to the break or skip the next reminder.
- Display hot-plug, orientation changes, wake, and shell restart must preserve
  one authoritative countdown rather than restart it.
- Accessibility includes labels and keyboard navigation, but also reduced
  motion, increased contrast, and selection cues that do not rely on color.

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
- Focus Filters: https://lookaway.com/docs/focus-filters/
- iPhone/iPad Sync: https://lookaway.com/docs/mobile-sync/
- Custom messages: https://lookaway.com/blog/2024/10/11/introducing-custom-messages-in-lookaway/
- Custom backgrounds and sounds: https://lookaway.com/blog/2024/12/05/custom-backgrounds-and-sounds-in-lookaway/
- Less-annoying design principles: https://lookaway.com/blog/2025/04/07/how-i-made-break-reminders-less-annoying/
- LookAway 1.10: https://lookaway.com/blog/2025/02/13/lookaway-110-wellness-reminders-and-more/
- LookAway 1.11: https://lookaway.com/blog/2025/03/19/lookaway-111-automations-focus-filters-and-more/
- LookAway 1.12: https://lookaway.com/blog/2025/04/30/lookaway-112-smarter-and-less-interruptive/
- LookAway 1.13: https://lookaway.com/blog/2025/06/09/lookaway-113-calendar-integration-overtime-nudges-and-more/
- LookAway 1.14: https://lookaway.com/blog/2025/07/23/lookaway-114-iphone-sync-is-finally-here/
- LookAway 2.0: https://lookaway.com/blog/2026/04/07/lookaway-20-screen-score-liquid-glass-and-more/
- LookAway 2.1: https://lookaway.com/blog/2026/04/23/lookaway-21-website-usage-stats-and-per-session-snooze-limits/
- LookAway 2.2: https://lookaway.com/blog/2026/06/22/lookaway-22-introducing-planned-breaks/
- LookAway 2.3: https://lookaway.com/blog/2026/07/22/lookaway-23-quieter-smarter-and-more-flexible/
- LookAway 2.4: https://lookaway.com/blog/2026/08/07/lookaway-24-live-activities-on-mac-and-iphone/
- Full changelog: https://lookaway.com/changelog/
- Sitemap coverage index: https://lookaway.com/sitemap.xml

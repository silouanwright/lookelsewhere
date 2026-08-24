# Experience and Surface Specification

## Experience sequence

```text
bar → quick panel (on demand)
bar → warning card → final countdown chip → break overlay → completion
```

All surfaces inherit the installed Omarchy design system. Fixed colors, radii, typography, borders, and desktop coordinates are prohibited unless they represent semantic data and have theme-aware fallbacks.

Surface roles remain distinct so themes can shape them independently:

- the bar widget consumes bar roles;
- the anchored quick panel and top-centered warning consume popup roles;
- tooltips consume tooltip roles;
- the full-screen break consumes modal/lock roles;
- shared controls consume Omarchy control-state tokens for normal, hover, pressed, selected, focus, border, and fill treatment.

Borders use Omarchy border specifications rather than flat `Rectangle.border`
styling. This preserves gradient, per-side, sharp-corner, rounded,
spacing-scale, typography-scale, and user `shell.toml` overrides.
LookElsewhere may add semantic iconography and hierarchy, but it does not
introduce a parallel theme system.

## Bar widget

The bar answers “when and why?” at a glance.

States:

- Working: compact remaining time or icon-only mode
- Due soon: restrained accent/progress treatment
- Protected: hold/shield treatment with category in tooltip/panel
- Paused: pause glyph and resume information
- Warning/breaking: active treatment without distracting animation
- Unavailable/recovery: disconnected or reconstructing state, never a false countdown

Primary action: open the quick panel. Secondary pointer actions may be added only if discoverable and keyboard-equivalent.

## Quick panel

Use Omarchy `Panel` and the current keyboard-capable popup primitive. Begin from the native compact width and fitted height.

Order:

1. Hero with current state and exact next-break time/status
2. One state-dependent primary action: Take break now, Resume, or Reconnect
3. Current routine summary
4. Smart Context explanation when relevant
5. Small today summary
6. Pause action

The main panel page must not contain full detector thresholds, routine
construction, history charts, or onboarding. Deeper controls belong on the
categorized settings pages.

## Warning card

- Top-centered on the selected interactive output with safe bar/edge offset
- Stable width and text geometry across countdown ticks
- Exact countdown, calm one-line explanation, and clear actions
- `Start now` primary; only policy-allowed postpone choices shown
- No exclusive focus by default
- Keyboard interaction must not cause accidental activation while the user is typing elsewhere
- If focus is intentionally requested, the transition and escape policy must be explicit

## Final countdown chip

- Replaces the warning for the last 3–5 seconds
- Smaller, stable, and noninteractive under the normal path
- No flash, bounce, growth, or urgency-color cycling
- Instant transition under reduced motion

## Break overlay

- One presentation per configured output
- Exactly one interactive authority on the focused/selected output
- Calm instruction, remaining time, and policy-dependent exit
- Theme-aware darkening or background treatment; no fixed entertainment artwork
- Optional minimal breathing cue, disabled under reduced motion
- Exclusive keyboard focus only when enforcement requires it
- Monitor hotplug cannot duplicate actions or reset the break

## Completion

The overlay exits cleanly, optionally plays a soft sound, records the local outcome, and resumes the next active-use interval. It does not demand a survey or celebratory modal.

## Settings

Configuration is declared by the typed manifest schema and stored by Omarchy in
`shell.json`. The panel provides categorized General, Breaks, Context, and
Experience pages. Changes use Omarchy's persistence API and flow back through
the same manifest-backed configuration contract, so the graphical controls do
not create a second source of truth.

The README documents safe `omarchy bar set` commands for scripting and direct
configuration. [`CONFIGURATION.md`](../CONFIGURATION.md) remains the complete
human-facing reference.

## Copy voice

- Calm, brief, and concrete
- Explain current behavior rather than moralizing
- Prefer “Waiting until your meeting ends” over internal terminology
- Prefer “Take break now” over vague “Start”
- Never claim medical outcomes
- Use “Look elsewhere” as an instruction sparingly enough to remain meaningful

# Design Research and Product Design System

This document turns the competitive, accessibility, LookAway, and Omarchy research into implementable design rules.

## Design position

The product should feel like an unusually thoughtful part of the desktop, not a branded productivity dashboard.

Three qualities define it:

1. **Quiet until useful** — no persistent visual pressure by default.
2. **Clear at transitions** — warnings and break state are unmistakable without being alarming.
3. **Deep when requested** — extensive configuration uses progressive disclosure and remains searchable.

The Omarchy integration inherits the active theme. The standalone settings client should use the same semantic token model so it remains visually coherent outside Omarchy without copying macOS materials.

## Research findings

### LookAway

- Uses a persistent settings sidebar with grouped sections.
- Uses rounded grouped rows rather than dense form tables.
- Shows behavioral choices, such as enforcement, with visual previews.
- Uses progressive warning surfaces: menu-bar status, top-center card, final countdown chip, full break state.
- Keeps reminder copy brief and reassuring.
- Makes common actions visible without opening settings.
- Invests in sound, background, motion, and position customization.

### Sane Break

- Its two-phase warning-to-break system is behaviorally strong.
- Configuration is functional but visually utilitarian.
- Demonstrates that stopping at a natural pause is more important than ornamental polish.

### Stretchly

- Offers enormous configuration depth, including break window sizing and behavior.
- Demonstrates the danger of pushing essential behavior into advanced configuration or JSON.
- Cross-platform abstraction weakens native Wayland behavior.

### Workrave and RSIBreak

- Strong modality vocabulary: microbreak, movement/rest break, exercises, daily limit.
- Strong enforcement choices, but visually dated and sometimes punitive.
- Exercise screens risk asking users to continue looking at the display during a supposed visual break.

### Platform guidance

- Notifications should be concise, high-value, and avoid repeating the same information excessively.
- Timed interactions need adjustable or suppressible behavior.
- Motion triggered by interaction should be disableable.
- Important information cannot depend only on sound, color, or animation.

References:

- Apple notification guidance: https://developer.apple.com/design/human-interface-guidelines/notifications/
- GNOME feedback patterns: https://developer.gnome.org/hig/patterns/feedback.html
- WCAG 2.2 timing, interruption, flashing, and animation guidance: https://www.w3.org/TR/wcag/

## Experience hierarchy

```text
Ambient       Bar indicator, usually hidden or compact
Awareness     Top-center warning card
Transition    Small final-countdown chip
Break         Calm full-output overlay or lock screen
Reflection    Optional local history/settings
```

Each level has a separate configuration switch. Disabling one level must not make the next level surprising; for example, disabling the heads-up should default to retaining the final countdown unless the user explicitly disables both.

## Visual language

### Color

Use semantic roles, never fixed brand colors in the Omarchy plugin:

- `surface`: current menu/panel background
- `surfaceRaised`: popup surface
- `text`: primary foreground
- `textMuted`: derived muted foreground
- `accent`: active theme accent
- `urgent`: destructive/error only
- `scrim`: theme scrim with user-configurable opacity
- `focusRing`: accent with minimum visible contrast

The current Omarchy shell provides `Color`, `Border`, and theme-aware surface roles. Use them directly in the QML plugin.

### Typography

Use the active Omarchy font family and its existing scale:

| Purpose | Omarchy token |
|---|---|
| Helper/caption | `Style.font.caption` |
| Secondary body | `Style.font.bodySmall` |
| Body/control | `Style.font.body` |
| Row title | `Style.font.subtitle` |
| Section title | `Style.font.heading` |
| Warning countdown | `Style.font.display` |
| Break countdown | `Style.font.displayLarge` or a proportional scale above it |

Do not use a separate decorative display font. Tabular numerals should be used for changing timers, and bar widths must remain stable as values change.

### Spacing and shape

Use `Style.spacing` and `Style.space()` rather than literal pixels:

- Controls: `controlHeight`, `controlPaddingX`, `controlPaddingY`
- Rows: `rowPaddingX`, `rowGap`
- Cards/panels: `panelPadding`, `panelGap`
- Popups: `popupPadding`
- Corners: `Style.cornerRadius`

The design must remain valid when the active theme sets square corners. Rounded cards are not part of the product identity.

### Borders and elevation

- Prefer theme border specifications over shadows.
- Use one raised-surface treatment for the warning and one for settings groups.
- Avoid stacking more than two bordered cards inside one another.
- Shadows are optional enhancement outside Omarchy and must not carry state meaning.

## Surface specifications

### Bar widget

Default modes:

- **Adaptive:** hidden when the next break is distant; appears during due-soon, overdue, suppressed, paused, or breaking states.
- **Countdown:** always shows fixed-width remaining time.
- **Icon:** state only.
- **Hidden:** keyboard/CLI control remains.

Interactions:

- Left click: Quick Panel
- Middle click: take next break now
- Right click: pause menu
- Wheel: no action by default; accidental schedule changes are too costly

The widget may use the indicator system for paused/suppressed status rather than showing two neighboring representations of the same state.

### Quick Panel

Target width: existing Omarchy popup convention, approximately `Style.space(280–340)`.

Contents:

1. Current state hero
2. Next routine and due time
3. Current context reason, only when relevant
4. Take break now
5. Pause/resume choices
6. Today’s completed/postponed/skipped summary
7. Open Settings

Do not expose routine editing in the Quick Panel.

### Heads-up warning

Placement:

- Centered horizontally on the active output
- Below a top bar or above a bottom bar using shell-provided safe insets
- User-selectable active monitor, pointer monitor, all monitors, or primary monitor
- Never cover the bar or pointer target currently being dragged

Anatomy:

```text
[routine icon]  00:23
                Almost time. Give your eyes a distant view.

[Start this break now] [+1m] [+5m] [+15m]
```

The warning uses a live region/accessibility announcement only once; it must not announce every countdown tick.

### Final countdown chip

- Appears for three to five seconds.
- Compact and noninteractive.
- Uses text and numerals, not animation alone.
- Placement may follow pointer with an offset or use a stable configured corner.
- Pointer-following is opt-in because moving UI can distract and complicate accessibility.

### Break overlay

The overlay’s purpose is to make leaving the screen easy. It should not reward staring at an animation.

Default visual-rest overlay:

- Dim/opaque calm field
- One instruction
- Countdown can become low-emphasis or disappear after the first few seconds
- Optional end sound so the user can look away completely
- Dismissal control initially low-emphasis according to enforcement policy

Movement/posture routines may show a sequence of static cards, but visual-rest routines should never require reading repeated instructions.

Background options:

- Theme surface
- Solid black
- Dimmed current wallpaper
- Static gradient derived from theme
- User image
- Animated ambient background, later and disabled with reduced motion or battery-saving policy

### Wellness nudge

- Small, nonmodal, configurable anchor
- No fullscreen dimming by default
- One icon, one short action phrase
- Auto-dismiss, but timing is configurable
- Separate cadence from screen breaks
- Hide from capture where supported; otherwise offer a recording-aware suppression policy

### Full settings window

- Persistent sidebar on wide windows
- Collapsible navigation/drawer on narrow windows
- Search field covering setting titles, descriptions, aliases, and detector names
- Page title and one-sentence explanation
- Grouped surfaces containing label, description, control, and optional detail navigation
- Changes apply immediately unless risky or expensive
- Per-page reset, plus global export/import/reset
- “Test” actions for warning, final countdown, overlay, sound, lock, and automation

## Settings navigation

Recommended order:

```text
Overview

Breaks
  Routines
  Smart Context
  Enforcement
  Break Experience

Feedback
  Alerts & Nudges
  Sounds
  History

System
  Shortcuts
  Automation
  Omarchy
  Privacy & Diagnostics

About
```

`Overview` is not a score-first dashboard. It shows the current state, next routine, sensor explanation, and a restrained summary of recent behavior.

## Configurability model

### Layer 1: Presets

Onboarding offers a few clearly described starting points:

- Gentle eye breaks
- Balanced recovery
- Deep focus
- Movement and posture
- Custom

Presets create editable routines; they are not permanent modes that hide underlying values.

### Layer 2: Routine editor

The normal editor exposes:

- Trigger/cadence
- Duration
- Work hours
- Warning
- Interruption behavior
- Content

### Layer 3: Advanced policy

Collapsed by default:

- Idle thresholds and partial credit
- Protected-context exit cooldown
- Break coalescing window
- Per-app rules
- Snooze budgets
- Catch-up behavior
- Automation environment/timeouts

### Layer 4: Declarative configuration

Power users can export/import a documented configuration format. The GUI remains authoritative and validates changes. Manual configuration errors must point to the exact routine and field.

## Motion specification

- Default motion uses opacity and short scale changes, not large travel.
- Warning entry: 140–200 ms opacity plus subtle scale from 0.98.
- Final chip: direct opacity transition; position remains stable.
- Break overlay: 250–400 ms scrim fade.
- No element loops indefinitely except an optional low-amplitude breathing cue.
- Reduced motion removes scale, travel, looping, parallax, and animated backgrounds.
- Never flash state faster than accessibility guidance permits.

## Sound specification

Events:

- Warning
- Break begins
- Break ends
- Wellness nudge
- Error/automation failure

Rules:

- Sound supplements visuals; it never replaces them.
- Defaults are short, soft, and distinct.
- Respect notification silencing/DND.
- Preview volume before saving.
- Do not automatically resume media unless this application paused it and the media state has not otherwise changed.

## Copy system

Voice: calm, concrete, nonjudgmental.

Prefer:

- “Almost time. Give your eyes a distant view.”
- “Waiting until your call ends.”
- “You were away for 3 of 5 minutes. Take the remaining 2?”
- “Break postponed until 2:35 PM.”

Avoid:

- “You failed your break.”
- “Unhealthy screen behavior.”
- “You must stop now.” except when the user explicitly configured locked enforcement
- Unsupported clinical claims

Every detector explanation should name the evidence category, not expose private content: “Microphone in use by a communication app,” not the meeting title or participants.

## Accessibility and resilience checklist

- Full keyboard navigation and visible focus
- Semantic labels for icon-only controls
- No color-only state
- Configurable timed interactions
- Reduced motion
- High-contrast compatibility
- Font and spacing scaling
- Screen-reader announcements at state changes, not every timer tick
- Multiple-monitor safe areas
- No overlay above the lock screen
- Emergency exit documented for strong enforcement
- Never trap input if the daemon/UI loses synchronization

## Deliberate non-goals

- Do not clone Liquid Glass or LookAway’s iconography.
- Do not make the default break visually entertaining enough to keep users watching.
- Do not expose every threshold during onboarding.
- Do not put all settings in the Omarchy bar popup.
- Do not make a health score the emotional center of the product.
- Do not use website history or window titles for basic smart detection.

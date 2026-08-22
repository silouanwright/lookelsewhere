# Competitive and Adversarial Matrix

Legend: **Strong**, **Partial**, **Weak**, **No**, or **Unknown** based on published product documentation as of 2026-08-22.

| Capability | LookAway | Sane Break | Workrave | RSIBreak | Stretchly | BreakTimer | Proposed app |
|---|---|---|---|---|---|---|---|
| Native Linux/Wayland focus | No | Strong | Weak | KDE-oriented | Partial | Partial | Strong |
| Reliable Wayland idle tracking | N/A | Strong | Unknown | KDE-dependent | Weak | Weak | Strong |
| Natural-pause escalation | Strong | Strong | Partial | Partial | Weak | Weak | Strong |
| Short and long routines | Strong | Partial | Strong | Strong | Strong | Partial | Strong |
| Planned clock-time breaks | Strong | Partial | Partial | Partial | Partial | Work hours | Strong |
| Full-screen overlay | Strong | Strong | Strong | Strong | Strong | Strong | Strong |
| Multi-monitor Wayland overlays | N/A | Strong | Unknown | KDE | Known limitations | Unknown | Required |
| Fullscreen-app suppression | Strong | Partial | Quiet mode | Strong | User pause | Rules | Strong on Hyprland |
| Video playback detection | Strong | Weak | Manual mode | Fullscreen heuristic | Weak | Weak | Confidence scored |
| Meeting/call detection | Strong | Weak | Manual mode | No | No | Rules | Confidence scored |
| Dictation detection | Strong | No | No | No | No | No | Microphone heuristic + adapters |
| Screen-sharing detection | Strong | No | No | No | No | No | Adapter/heuristic; not guaranteed |
| Exercises/movement content | Limited | Limited | Strong | Limited | Strong | Custom messages | Routine content packs |
| Posture/blink nudges | Strong | Limited | Microbreaks | No | Break ideas | Custom messages | Routine types |
| Daily usage limit | Stats | No | Strong | Partial | No | No | Later |
| Enforcement choices | Strong | Strong | Strong | Strong | Partial | Partial | Four explicit levels |
| Automations/hooks | Strong | No | Partial | Partial | Partial | No | Strong |
| CLI/API | Automations | No documented stable API | Partial | No | Protocol links | Minimal CLI | Stable D-Bus + CLI |
| Local/private operation | Strong | Strong | Strong | Strong | Strong | Strong | Strong and documented |
| Omarchy integration | No | No | No | No | No | No | First class |

## What could invalidate the project

### Sane Break closes the gap

Sane Break already implements the hardest basic interaction: a gentle warning that becomes a break when the user naturally stops. If the proposed app ships only timers and an attractive overlay, it has no durable reason to exist.

### Smart detection produces false confidence

Linux does not expose one authoritative “in a meeting” state. A microphone stream may be dictation, recording, a voice chat, or a browser permission test. Audio playback may be music rather than video. Fullscreen may be a presentation, game, video, or focused editor. The app must combine evidence, expose why it acted, and allow per-app corrections.

### Enforcement damages trust

Users rapidly learn to dismiss predictable prompts. Stronger enforcement can create resentment or cause uninstallation. The product must optimize for adherence over time, not maximum interruption strength. Postponement budgets and natural-pause escalation are preferable to hidden or manipulative restrictions.

### The audience is too narrow

Hyprland users are a viable design-partner audience, not necessarily a large business by themselves. The core should use standard Wayland/PipeWire/D-Bus interfaces and isolate compositor-specific behavior behind adapters.

### Maintenance surface becomes unbounded

Browser extensions, editor plugins, conference-app adapters, multiple compositors, portals, packaging formats, and mobile sync can overwhelm the project. Only build an adapter when it materially improves a high-frequency scenario and can fail safely.

### Health marketing outruns evidence

Regular breaks and ergonomics are reasonable wellness goals, but the exact 20-20-20 formula has mixed evidence. Avoid claims that the application treats disease, prevents myopia, or guarantees reduced eye strain.

## Defensible differentiation

1. Best-in-class Wayland and Hyprland behavior.
2. Explainable, confidence-scored interruption decisions.
3. Several user-selectable recovery modalities sharing one coherent engine.
4. A polished Omarchy integration without coupling the core to Omarchy Shell.
5. Privacy: metadata-derived context, no content capture, local aggregates only.
6. Reliable state across suspend, lock, shell restart, daemon restart, and monitor changes.

## Sources

- LookAway documentation: https://lookaway.com/docs/introduction/
- Sane Break: https://github.com/AllanChain/sane-break
- Workrave: https://workrave.org/docs/settings/ui/
- RSIBreak handbook: https://docs.kde.org/trunk5/en/rsibreak/rsibreak/rsibreak.pdf
- Stretchly: https://github.com/hovancik/stretchly
- BreakTimer: https://github.com/tom-james-watson/breaktimer-app

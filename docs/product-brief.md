# Product Brief

## One sentence

Look Elsewhere is a native Omarchy break coach that understands what the user is doing and interrupts at a less disruptive moment.

## User and problem

The primary user spends long periods coding, writing, reading, designing, gaming, or communicating on an Omarchy desktop. Ordinary timers count absence as work, interrupt meetings or media, lose state on restart, and train users to dismiss reminders. Existing polished context-aware products primarily target macOS.

## Differentiation

1. Active-use time instead of a blind wall-clock interval.
2. Explainable Smart Context for idle, fullscreen, media, microphone/meeting, and dictation signals.
3. Progressive interruption: bar state → warning card → final chip → break overlay.
4. First-class Omarchy integration through Quickshell, native components, themes, IPC, Hyprland, MPRIS, and PipeWire.
5. Local, metadata-minimizing operation without accounts, analytics, or content capture.

## Product principles

- **Judge interruption quality, not user virtue.** The product should improve timing rather than reward streak manipulation.
- **Explain delays.** Say “Waiting until your meeting ends,” not “Smart Pause active.”
- **Stay quiet until useful.** The bar is glanceable; deep configuration does not live in a popup.
- **Respect agency.** Balanced remains the default; Hardcore lockout is an explicit configuration choice with disclosed consequences and still permits bounded snoozing.
- **Inherit Omarchy.** Personality comes from information design, language, and one recognizable symbol—not fixed custom chrome.
- **Minimize observation.** Context categories are transient; titles, URLs, meeting names, transcripts, and content are neither stored nor displayed by default.

## Competition demonstration

The deterministic demo should take roughly 30–45 seconds:

1. Open the native bar panel and show an upcoming break.
2. Stage a protected meeting/video context and show an intelligible delay reason.
3. End the context and show cooldown/natural-pause behavior.
4. Trigger the top-centered warning with `Start now` and postpone actions.
5. Transition to the final countdown chip.
6. Show the theme-aware multi-monitor break overlay.
7. Complete the break and return to the resumed timer.

The demo must use synthetic fixture state and must not inspect real private content.

## Non-goals for the competition MVP

- Cloud or mobile synchronization
- Accounts, telemetry, or advertising
- Website/application usage history
- Camera inference or content analysis
- App-specific browser/conferencing extensions
- A large exercise or wellness-content library
- Gamification, streak pressure, health scores, or AI recommendations
- Cross-compositor support beyond clean internal boundaries
- A separate durable daemon unless feasibility proves Quickshell persistence inadequate

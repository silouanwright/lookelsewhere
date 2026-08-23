# Look Elsewhere

A private, context-aware break coach built natively for Omarchy. Look Elsewhere
counts active screen use, waits through protected moments such as meetings,
video, fullscreen work, and dictation, then finds a better moment to pull your
attention away from the screen.

Inspired by [LookAway](https://lookaway.com/), a beautifully considered Mac app,
and reimagined for Omarchy, Wayland, and a keyboard-first Linux desktop.

![Look Elsewhere break overlay](preview.png)

## Why Look Elsewhere?

Most Linux break timers interrupt on a wall-clock schedule. Look Elsewhere pays
attention to whether you are actually using the computer and whether a break
would be disruptive right now.

It is a self-contained Quickshell/QML plugin, not an Electron app. It follows
your Omarchy theme, lives in the bar, understands Hyprland and Wayland signals,
works without a mouse, and keeps everything on your machine.

## Features

- Active-use scheduling with recovery across shell reloads
- Idle, fullscreen, focused-video, microphone, dictation, and protected-app detection
- Progressive warning, final countdown, and multi-monitor break overlay
- Casual, Balanced, and Hardcore enforcement
- Configurable short breaks, long breaks, snoozing, office hours, and sounds
- Native Omarchy surfaces that follow contrasting, rounded, and sharp themes
- Complete keyboard navigation with direct action keys and visible hints
- No account, telemetry, screen capture, audio recording, or retained activity titles

## From glance to break

Look Elsewhere starts in the bar, opens an anchored control panel, warns you at
the top center of the active display, then becomes a calm full-screen break.

![Look Elsewhere top-centered warning](docs/assets/progressive-warning.png)

[Watch the 23-second warning-to-break demo](docs/assets/demo.mp4). It uses
synthetic state and restores the real schedule when it finishes.

Periodic long breaks use the same themed surface with a clear status pill and a
longer countdown.

![Look Elsewhere long-break overlay](docs/assets/long-break.png)

## Install

```bash
omarchy plugin add https://github.com/silouanwright/lookelsewhere.git --enable
```

Look Elsewhere requires Omarchy Quattro with Omarchy Shell. It has no installer
hook, privileged operation, external daemon, account, or network dependency.

## Keyboard-native control

Press `?` to reveal every direct action key. Inspired by
[Godspeed](https://godspeedapp.com/), the badges make keyboard control visible,
inherit the active Omarchy theme, and deactivate when another shell surface
takes focus.

![Look Elsewhere keyboard shortcut hints](docs/assets/quick-panel.png)

Tab and Shift+Tab traverse every control, Enter or Space activates it, and
Escape closes the panel. Local action keys are configurable in
[Configuration](CONFIGURATION.md).

For global invocation, add the recommended `Super+Alt+L` Omarchy binding:

```lua
o.bind("SUPER + ALT + L", "LookElsewhere", "omarchy-shell look-elsewhere-panel toggle")
```

## Configure

Look Elsewhere follows Omarchy's config-first plugin convention. Use the bar
CLI to change a setting without editing `~/.config/omarchy/shell.json` by hand:

```bash
omarchy bar set io.github.silouanwright.look-elsewhere focusMinutes 25 --json
omarchy bar set io.github.silouanwright.look-elsewhere enforcement '"balanced"' --json
```

Timing, long breaks, detectors, enforcement, snoozing, office hours, sounds,
display modes, protected apps, guidance text, outputs, motion, and shortcuts are
all configurable. See [Configuration](CONFIGURATION.md) for every option,
default, accepted value, and example.

## How smart timing works

Only active screen use advances the focus timer. When a break becomes due,
Look Elsewhere briefly looks for strong local evidence that interruption would
be disruptive. It can wait through:

- idle and away time;
- fullscreen applications and configured protected apps;
- media playing in the focused application;
- active microphone or meeting-like activity; and
- Omarchy dictation.

The bar always reflects why time is being held. Detection uses coarse local
state only. Look Elsewhere does not store media titles, window titles,
transcripts, audio, or screen content.

## Enforcement

- **Casual:** breaks may be snoozed or skipped.
- **Balanced:** bounded snoozing with a more deliberate skip interaction.
- **Hardcore:** bounded snoozing before the break, but no skipping once it begins.

Hardcore ends only when the break timer completes.

## Limitations

- Hyprland and Omarchy are the supported and tested environment.
- MPRIS does not identify whether the current item has a video track. Look
  Elsewhere infers video only when the playing application is focused, which
  avoids pausing for background music but remains a heuristic.
- Wayland exposes coarse application and device state, not semantic intent.
  Screen sharing, recording, and every meeting state cannot yet be identified
  perfectly without upstream support.
- The scheduler currently lives inside Quickshell. Timestamp persistence makes
  shell reloads recoverable, but a separate daemon may become appropriate for
  broader Linux support later.

The platform improvements uncovered while building this are documented in
[Upstream Opportunities](docs/upstream-opportunities.md).

## Roadmap

- Better private statistics and break history
- Smarter return-from-away behavior
- Stronger meeting, screen-sharing, recording, video, and per-app signals
- Optional glanceable break ideas and more short- and long-break routines
- More sound choices, previews, and optional start/end hooks
- A graphical settings experience after the config-first release
- Clean foundations for other Quickshell and Wayland desktops

New features should stay private, explainable, keyboard-accessible, and native
to Omarchy. A calm break tool should not become another dashboard demanding
attention.

## Development

Deterministic demo states, verification evidence, architecture decisions, and
the completion matrix live under [Documentation](docs/README.md). Start with:

```bash
omarchy-shell look-elsewhere demo flow
omarchy-shell look-elsewhere demo long-break
omarchy-shell look-elsewhere demoOff
```

Demo fixtures never persist synthetic state.

## A note from the developer

I'm Silouan Wright, a lead frontend engineer who has been building software for
over 20 years. I've used Omarchy since its first release, and building Look
Elsewhere reminded me how much I want to come back to work on something I
genuinely love.

I built this plugin in close collaboration with an AI coding agent. What
interests me is not just generating code. It is directing a long-running effort
with judgment: doing the research, making product decisions, communicating
precise feedback, testing assumptions, and noticing the difference between
something that technically works and something that actually feels right.

The agent made me much faster, but it did not decide what good looked like. In
roughly 14 hours of sustained work, I moved from competitive research through
architecture, implementation, visual refinement, accessibility, documentation,
runtime testing, and release hardening. I care as much about the state machine
under an interface as I do about the last few pixels people experience.

Working on Omarchy with agentic development has made building software exciting
for me again. I would love to bring that combination of engineering experience,
product judgment, communication, and attention to detail to Omarchy full time.

If this reaches DHH or the Omarchy team, I would genuinely love to talk. If Look
Elsewhere wins a competition prize, I'll donate the money to charity. The real
prize would be getting to work on something like this again.

## License

[MIT](LICENSE). Created by [Silouan Wright](https://github.com/silouanwright).

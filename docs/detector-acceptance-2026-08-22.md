# Detector Acceptance — 2026-08-22

All checks used the installed plugin with demo mode off. The active schedule was
preserved. Media was returned to paused after testing.

| Signal | Result | Evidence |
|---|---|---|
| Focused-app MPRIS playback | Passed | Playing Chromium behind a fullscreen Steam game correctly emitted no playback evidence. After the game released focus, focused Chromium with MPRIS `Playing` emitted `media` evidence at confidence `0.8` and the `Video` context label; pausing cleared both. |
| Hyprland fullscreen | Passed | A focused native window emitted and cleared fullscreen evidence. A live XWayland Steam game also reported mode `2` through focus-triggered reconciliation. |
| Protected application | Passed | The focused `steam_app_1868140` game matched the default `steam` policy and emitted `application` evidence at confidence `1`, producing the `Focus` bar state. |
| Final-ten-second input hold | Passed | Modifier-only input through the real Wayland input path produced `Active` and repeatedly held the deadline at 10,000 ms. Recent input is retained for two seconds—longer than the one-second scheduler interval—to avoid phase-dependent misses; after that quiet window, the hold clears and the countdown resumes. Wayland does not distinguish this from pointer activity. |
| Omarchy dictation | Blocked below plugin | `voxtype record start` reached the daemon, but Voxtype failed to create its ALSA stream (`snd_pcm_hw_params`: no such file or directory) and returned to `idle` before it could emit recording state. No transcription was produced. |
| PipeWire microphone | Blocked below plugin | A discard-only `pw-record` probe failed with `no target node available`; no capture stream existed for LookElsewhere to observe. |
| Wayland idle | Inconclusive in this session | The five-second natural-pause signal worked. Chromium repeatedly auto-resumed its MPRIS video during the 60-second idle window, contaminating the accounting test. No client idle-inhibitor flag was present. |

## Accounting contract observed

Idle is the only detector that currently stops active-time accumulation.
Playback, configured applications, fullscreen, microphone/meeting, and dictation are protected-context
signals: focus time continues to accumulate, but a due interruption is held
until the context clears or the configured maximum delay is reached. Changing
those signals to pause accumulation would be a separate Smart Pause policy.

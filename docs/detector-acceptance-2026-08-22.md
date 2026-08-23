# Detector Acceptance — 2026-08-22

All checks used the installed plugin with demo mode off. The active schedule was
preserved. Media was returned to paused after testing.

| Signal | Result | Evidence |
|---|---|---|
| MPRIS media | Passed | Chromium changed from `Paused` to `Playing`; LookElsewhere immediately emitted `media` at confidence `0.8`, the bar changed from the countdown to `Media`, and both cleared after pause. |
| Hyprland fullscreen | Passed | The focused window entered Hyprland fullscreen mode `2`; LookElsewhere emitted `fullscreen` at confidence `0.65`, then cleared it immediately when fullscreen ended. |
| Omarchy dictation | Blocked below plugin | `voxtype record start` reached the daemon, but Voxtype failed to create its ALSA stream (`snd_pcm_hw_params`: no such file or directory) and returned to `idle` before it could emit recording state. No transcription was produced. |
| PipeWire microphone | Blocked below plugin | A discard-only `pw-record` probe failed with `no target node available`; no capture stream existed for LookElsewhere to observe. |
| Wayland idle | Inconclusive in this session | The five-second natural-pause signal worked. Chromium repeatedly auto-resumed its MPRIS video during the 60-second idle window, contaminating the accounting test. No client idle-inhibitor flag was present. |

## Accounting contract observed

Idle is the only detector that currently stops active-time accumulation.
Media, fullscreen, microphone/meeting, and dictation are protected-context
signals: focus time continues to accumulate, but a due interruption is held
until the context clears or the configured maximum delay is reached. Changing
those signals to pause accumulation would be a separate Smart Pause policy.

# Competition Completion Matrix

Status reflects inspected repository and installed-runtime evidence on 2026-08-25. `Implemented` is not equivalent to release-verified.

| Requirement | Status | Current evidence / remaining proof |
|---|---|---|
| Active-use focus and break scheduling | Implemented | `Model.observe`, manifest settings, pure tests |
| Timestamp persistence and restart recovery | Implemented | Atomic state snapshot plus five-second rollback bound, long-suspend, expired-warning, and expired-break reconciliation tests exist; live invalid-JSON acceptance proved preservation, blocked writes, warning visibility, exact restoration, and clean reload |
| Office hours, including overnight | Implemented | Daytime boundaries, equal-bound all-day behavior, overnight schedules, and pause-to-open accounting are covered by pure tests |
| Manual pause/resume | Implemented | Service IPC, state-aware quick-panel Pause/Resume action, and paused fixture |
| Idle detection | Implemented | Wayland idle monitor plus live `idle` fixture proving bar pause/resume presentation |
| Fullscreen detection | Implemented | Event-driven Quickshell active-toplevel state plus focus-triggered XWayland reconciliation; the live fullscreen Steam game reported mode `2` without continuous polling |
| Playback detection | Implemented heuristic | Focused-app MPRIS playback plus explicit active PipeWire `Movie` role; live Chromium omitted both current-item type and PipeWire role, so exact audio/video classification remains an upstream limitation |
| Protected applications | Implemented | Manifest-backed application IDs default to `steam`; live Steam client and `steam_app_<id>` matching plus focused XWayland evidence were verified |
| Microphone/meeting/sharing detection | Implemented with declared-signal limits | Active PipeWire links are shaped outside QML into bounded Capture, Communication, Camera, Screen, and Movie evidence; live microphone capture passed while application role adoption remains variable |
| Dictation detection | Implemented | Managed `omarchy-voxtype-status` event stream matches Omarchy's native Dictation indicator and exposes capability diagnostics |
| Confidence policy, natural pause, typing hold, cooldown, maximum delay | Implemented | Five-second Wayland input-quiet gate, final-ten-second typing hold, protected-context precedence, cooldown, and hard-delay bound have deterministic tests; live input held at 10 seconds, with a tunable two-second recent-input window that exceeds the scheduler interval |
| Bar and anchored quick panel | Implemented | Installed and exercised with status-only content, keyboard actions, and correct inward anchoring on every bar edge |
| Warning, final chip, break overlay | Implemented | Deterministic fixtures and approved theme-aware break transition |
| Multi-monitor single authority | Implemented | Focused-monitor authority in `Overlay.qml`; a compositor output created during an active break immediately rendered the full surface and was removed cleanly; physical mixed-scale focus handoff remains future hardware QA |
| Casual/Balanced/Hardcore enforcement | Implemented | Casual and Balanced permit bounded snoozing and skip; Hardcore permits bounded snoozing but rejects pointer, IPC, Escape, and modified-Escape skip until natural completion; legacy policy names migrate safely |
| MVP configuration contract | Implemented | Typed short/long timing, custom break copy, policy, detector, motion, sound, output, and bar settings are wired; README documents `omarchy bar set` and local reset |
| Private statistics | Implemented | Daily active time, current/longest/median sessions, short/long completed breaks, snoozes, skips, natural-away outcomes, seven-day summaries, bounded persistence, and reset IPC are covered by pure tests and a dedicated Stats view |
| Privacy boundary | Implemented by design | No content capture/title persistence/network calls; release audit remains |
| Deterministic fixtures | Implemented | Working/due/idle/paused/postponed/protected/typing/warning/final/break/recovery/enforcement plus timer-driven `flow` exist and restore real state |
| Keyboard and accessibility | Implemented | Native button roles/names/actions, top-to-bottom Options cursor navigation, editor/dropdown Escape restoration, deterministic Tab/Backtab order, panel-local mnemonic actions, optional conflict-checked global Omarchy bindings, Hardcore lockout, and reduced-motion behavior; live keyboard evidence and clean runtime logs recorded |
| Theme and bar-position QA | Implemented | Osaka Jade and Catppuccin Latte plus top/bottom/left/right were exercised live and restored; transient panel IPC lifecycle issue found and fixed |
| Automated tests and QML review | Implemented | 91 passing model/component tests plus bounded PipeWire and input checks and an installed-runtime reliability harness covering protected-context fixtures, timer-driven warning/final/break flow, exact configuration restoration, planned breaks, statistics, countdown sequencing, keyboard behavior, enforcement, and sounds |
| Public packaging | Implemented | Manifest, rights notices, release README, exact final-UI preview/panel/warning/long-break assets and 23-second demo, marketplace draft, clean provenance audit, isolated add/validate/remove proof, and live panel-owned disable/re-enable proof exist |
| Competition submission | Submitted | Public repository and [marketplace issue #1785](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/1785) exist; review status lives on the issue |

## Current status

This matrix is a release snapshot from 2026-08-22. Current marketplace review
status lives on [issue #1785](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/1785).

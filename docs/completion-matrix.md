# Competition Completion Matrix

Status reflects inspected repository and installed-runtime evidence on 2026-08-22. `Implemented` is not equivalent to release-verified.

| Requirement | Status | Current evidence / remaining proof |
|---|---|---|
| Active-use focus and break scheduling | Implemented | `Model.observe`, manifest settings, pure tests |
| Timestamp persistence and restart recovery | Implemented | Atomic state snapshot plus five-second rollback bound, long-suspend, expired-warning, and expired-break reconciliation tests exist; live invalid-JSON acceptance proved preservation, blocked writes, warning visibility, exact restoration, and clean reload |
| Office hours, including overnight | Implemented | Daytime boundaries, equal-bound all-day behavior, overnight schedules, and pause-to-open accounting are covered by pure tests |
| Manual pause/resume | Implemented | Service IPC, state-aware quick-panel Pause/Resume action, and paused fixture |
| Idle detection | Implemented | Wayland idle monitor plus live `idle` fixture proving bar pause/resume presentation |
| Fullscreen detection | Implemented | Event-driven Quickshell active-toplevel state plus focus-triggered XWayland reconciliation; the live fullscreen Steam game reported mode `2` without continuous polling |
| Playback detection | Implemented heuristic | Focused-app MPRIS playback with a manifest-backed toggle; live background Chromium playback was correctly ignored, while exact audio/video classification remains an upstream MPRIS limitation |
| Protected applications | Implemented | Manifest-backed application IDs default to `steam`; live Steam client and `steam_app_<id>` matching plus focused XWayland evidence were verified |
| Microphone/meeting detection | Partial | PipeWire stream heuristic works locally; communication classification and availability explanation remain |
| Dictation detection | Implemented | Managed `omarchy-voxtype-status` event stream matches Omarchy's native Dictation indicator and exposes capability diagnostics |
| Confidence policy, natural pause, typing hold, cooldown, maximum delay | Implemented | Five-second Wayland input-quiet gate, final-ten-second typing hold, protected-context precedence, cooldown, and hard-delay bound have deterministic tests; live input held at 10 seconds and resumed after one quiet second |
| Bar and anchored quick panel | Implemented | Installed and exercised with status-only content, keyboard actions, and correct inward anchoring on every bar edge |
| Warning, final chip, break overlay | Implemented | Deterministic fixtures and approved theme-aware break transition |
| Multi-monitor single authority | Implemented | Focused-monitor authority in `Overlay.qml`; a compositor output created during an active break immediately rendered the full surface and was removed cleanly; physical mixed-scale focus handoff remains future hardware QA |
| Casual/Balanced/Hardcore enforcement | Implemented | Casual and Balanced permit bounded snoozing and skip; Hardcore permits bounded snoozing but rejects pointer, IPC, Escape, and modified-Escape skip until natural completion; legacy policy names migrate safely |
| MVP configuration contract | Implemented | Typed short/long timing, custom break copy, policy, detector, motion, sound, output, and bar settings are wired; README documents `omarchy bar set` and local reset |
| Outcome totals | Implemented | Prompted/completed/postponed/skipped/delayed persist, compact history summary is visible, and reset IPC exists |
| Privacy boundary | Implemented by design | No content capture/title persistence/network calls; release audit remains |
| Deterministic fixtures | Implemented | Working/due/idle/paused/postponed/protected/typing/warning/final/break/recovery/enforcement plus timer-driven `flow` exist and restore real state |
| Keyboard and accessibility | Implemented | Native button roles/names/actions, deterministic Tab/Backtab order, Escape dismissal, panel-local mnemonic actions, optional conflict-checked global Omarchy bindings, Hardcore lockout, and reduced-motion behavior; live keyboard evidence and clean runtime logs recorded |
| Theme and bar-position QA | Implemented | Osaka Jade and Catppuccin Latte plus top/bottom/left/right were exercised live and restored; transient panel IPC lifecycle issue found and fixed |
| Automated tests and QML review | Implemented | 52 passing model/component tests, including protected applications, focused-player matching, typing holds, protected-context bar labels, configurable shortcuts, missed-tick sequencing, long-break cadence, policy migration, Hardcore skip policy, and lead-timed sound transitions; the wide review and remediation recheck are clean |
| Public packaging | In final verification | Manifest, rights notices, release README, marketplace draft, clean provenance audit, isolated add/validate/remove proof, and live panel-owned disable/re-enable proof exist; original preview/demo assets must be recaptured from the exact final UI |
| Competition submission | Missing | External publication and marketplace submission require final authorization |

## Immediate release sequence

1. Recapture the original stills and demo from the exact final UI, then rerun
   their visual and provenance checks.
2. Complete the focused-browser half of live playback acceptance after the
   active fullscreen game releases focus.
3. Present the exact distributable commit for publication approval.
4. After approval, create the public repository, verify installation from its
   URL, and request final approval of the marketplace issue body.

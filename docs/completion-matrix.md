# Competition Completion Matrix

Status reflects inspected repository and installed-runtime evidence on 2026-08-22. `Implemented` is not equivalent to release-verified.

| Requirement | Status | Current evidence / remaining proof |
|---|---|---|
| Active-use focus and break scheduling | Implemented | `Model.observe`, manifest settings, pure tests |
| Timestamp persistence and restart recovery | Implemented | Atomic state snapshot plus rollback, long-suspend, expired-warning, and expired-break reconciliation tests exist; live invalid-JSON acceptance proved preservation, blocked writes, warning visibility, exact restoration, and clean reload |
| Office hours, including overnight | Implemented | Daytime boundaries, equal-bound all-day behavior, overnight schedules, and pause-to-open accounting are covered by pure tests |
| Manual pause/resume | Implemented | Service IPC, state-aware quick-panel Pause/Resume action, and paused fixture |
| Idle detection | Implemented | Wayland idle monitor plus live `idle` fixture proving bar pause/resume presentation |
| Fullscreen detection | Implemented | Event-driven Quickshell active-toplevel fullscreen state with capability diagnostics |
| Media detection | Implemented | Quickshell MPRIS playback state with manifest-backed detector toggle |
| Microphone/meeting detection | Partial | PipeWire stream heuristic works locally; communication classification and availability explanation remain |
| Dictation detection | Implemented | Managed `omarchy-voxtype-status` event stream matches Omarchy's native Dictation indicator and exposes capability diagnostics |
| Confidence policy, natural pause, cooldown, maximum delay | Implemented | Five-second Wayland input-quiet gate, protected-context precedence, cooldown, and hard-delay bound have deterministic tests |
| Bar and anchored quick panel | Implemented | Installed and exercised with status-only content, keyboard actions, and correct inward anchoring on every bar edge |
| Warning, final chip, break overlay | Implemented | Deterministic fixtures and approved theme-aware break transition |
| Multi-monitor single authority | Implemented | Focused-monitor authority in `Overlay.qml`; hotplug/action tests remain |
| Gentle/Balanced/Focused enforcement | Implemented | Policy-specific actions, bounded snoozing, documented consequences, and live Focused `Ctrl+Shift+Esc` emergency-exit proof |
| MVP configuration contract | Implemented | Typed timing, policy, detector, motion, sound, output, and bar settings are wired; README documents `omarchy bar set` and local reset |
| Outcome totals | Implemented | Prompted/completed/postponed/skipped/delayed persist, compact history summary is visible, and reset IPC exists |
| Privacy boundary | Implemented by design | No content capture/title persistence/network calls; release audit remains |
| Deterministic fixtures | Implemented | Working/due/idle/paused/postponed/protected/warning/final/break/recovery/enforcement plus timer-driven `flow` exist and restore real state |
| Keyboard and accessibility | Implemented | Native button roles/names/actions, deterministic Tab/Backtab order, Escape dismissal, Focused emergency exit, and reduced-motion behavior; live focus screenshots and clean runtime logs recorded |
| Theme and bar-position QA | Implemented | Osaka Jade and Catppuccin Latte plus top/bottom/left/right were exercised live and restored; transient panel IPC lifecycle issue found and fixed |
| Automated tests and QML review | Partial | 27 model tests, manifest validation, system qmllint, six-pass semantic review, live flow proof, and keyboard acceptance evidence exist; release acceptance matrix remains |
| Public packaging | Partial | Manifest, MIT license, release README, root `preview.png`, marketplace draft, and isolated add/validate/remove proof exist; final public-asset and verified-commit audit remains |
| Competition submission | Missing | External publication and marketplace submission require final authorization |

## Immediate release sequence

1. Complete the remaining runtime acceptance matrix, including the feasible
   scaled/narrow-output and keyboard-focus checks.
2. Produce the final original preview/demo assets and finish the release README.
3. Audit the exact distributable commit, then request publication and submission approval.

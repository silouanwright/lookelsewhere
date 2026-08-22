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
| Multi-monitor single authority | Implemented | Focused-monitor authority in `Overlay.qml`; a compositor output created during an active break immediately rendered the full surface and was removed cleanly; physical mixed-scale focus handoff remains future hardware QA |
| Gentle/Balanced/Focused enforcement | Implemented | Policy-specific actions, bounded snoozing, documented consequences, and live Focused `Ctrl+Shift+Esc` emergency-exit proof |
| MVP configuration contract | Implemented | Typed timing, policy, detector, motion, sound, output, and bar settings are wired; README documents `omarchy bar set` and local reset |
| Outcome totals | Implemented | Prompted/completed/postponed/skipped/delayed persist, compact history summary is visible, and reset IPC exists |
| Privacy boundary | Implemented by design | No content capture/title persistence/network calls; release audit remains |
| Deterministic fixtures | Implemented | Working/due/idle/paused/postponed/protected/warning/final/break/recovery/enforcement plus timer-driven `flow` exist and restore real state |
| Keyboard and accessibility | Implemented | Native button roles/names/actions, deterministic Tab/Backtab order, Escape dismissal, Focused emergency exit, and reduced-motion behavior; live focus screenshots and clean runtime logs recorded |
| Theme and bar-position QA | Implemented | Osaka Jade and Catppuccin Latte plus top/bottom/left/right were exercised live and restored; transient panel IPC lifecycle issue found and fixed |
| Automated tests and QML review | Implemented | 38 passing model/component tests, manifest validation, system qmllint, two six-pass semantic reviews, remediations, live flow proof, hotplug proof, and keyboard acceptance evidence exist |
| Public packaging | Implemented | Manifest, rights notices, release README, current original root preview, panel/warning stills, 21-second deterministic demo, marketplace draft, clean provenance audit, isolated add/validate/remove proof, and live panel-owned disable/re-enable proof exist |
| Competition submission | Missing | External publication and marketplace submission require final authorization |

## Immediate release sequence

1. Re-run automated and source gates against the final documentation commit.
2. Present the exact distributable commit for publication approval.
3. After approval, create the public repository, verify installation from its
   URL, and request final approval of the marketplace issue body.

# Competition Completion Matrix

Status reflects inspected repository and installed-runtime evidence on 2026-08-22. `Implemented` is not equivalent to release-verified.

| Requirement | Status | Current evidence / remaining proof |
|---|---|---|
| Active-use focus and break scheduling | Implemented | `Model.observe`, manifest settings, pure tests |
| Timestamp persistence and restart recovery | Partial | Atomic state snapshot exists; suspend/clock-jump and corrupt-state acceptance tests remain |
| Office hours, including overnight | Implemented | Pure overnight test plus manifest-backed configuration; boundary/runtime schedule QA remains |
| Manual pause/resume | Implemented | Service IPC, state-aware quick-panel Pause/Resume action, and paused fixture |
| Idle detection | Implemented | Wayland idle monitor plus live `idle` fixture proving bar pause/resume presentation |
| Fullscreen detection | Implemented | Event-driven Quickshell active-toplevel fullscreen state with capability diagnostics |
| Media detection | Implemented | Quickshell MPRIS playback state with manifest-backed detector toggle |
| Microphone/meeting detection | Partial | PipeWire stream heuristic works locally; communication classification and availability explanation remain |
| Dictation detection | Implemented | Managed `omarchy-voxtype-status` event stream matches Omarchy's native Dictation indicator and exposes capability diagnostics |
| Confidence policy, cooldown, maximum delay | Implemented | Pure policy and precedence exist; broader boundary tests remain |
| Bar and anchored quick panel | Implemented | Installed and exercised; state/action/accessibility matrix remains |
| Warning, final chip, break overlay | Implemented | Deterministic fixtures and approved theme-aware break transition |
| Multi-monitor single authority | Implemented | Focused-monitor authority in `Overlay.qml`; hotplug/action tests remain |
| Gentle/Balanced/Focused enforcement | Implemented | Policy-specific actions, bounded snoozing, documented consequences, and Focused `Ctrl+Shift+Esc` emergency exit; live keyboard proof remains |
| MVP configuration contract | Implemented | Typed timing, policy, detector, motion, sound, output, and bar settings are wired; README documents `omarchy bar set` and local reset |
| Outcome totals | Implemented | Prompted/completed/postponed/skipped/delayed persist, compact history summary is visible, and reset IPC exists |
| Privacy boundary | Implemented by design | No content capture/title persistence/network calls; release audit remains |
| Deterministic fixtures | Implemented | Working/due/idle/paused/postponed/protected/warning/final/break/recovery/enforcement plus timer-driven `flow` exist and restore real state |
| Keyboard and accessibility | Partial | Native controls, break Escape path, and reduced-motion behavior exist; focus-order/name tests remain |
| Theme and bar-position QA | Partial | Native roles and anchored panel implemented; full contrasting-theme/bar-position matrix remains |
| Automated tests and QML review | Partial | 17 model tests, manifest validation, system qmllint, six-pass semantic review, and live flow proof exist; component/accessibility automation remains |
| Public packaging | Missing | Manifest validates; license, preview, release README, marketplace metadata, and clean install/remove proof remain |
| Competition submission | Missing | External publication and marketplace submission require final authorization |

## Immediate release sequence

1. Expose and wire every MVP configuration value, including reduced motion and privacy reset.
2. Harden detector availability, persistence recovery, enforcement budgets, and fixture coverage.
3. Complete keyboard/accessibility, automated tests, runtime logs, theme/bar/multi-monitor QA.
4. Produce preview/demo assets, packaging metadata, clean-install proof, and submission materials.

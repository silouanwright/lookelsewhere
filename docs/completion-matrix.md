# Competition Completion Matrix

Status reflects inspected repository and installed-runtime evidence on 2026-08-22. `Implemented` is not equivalent to release-verified.

| Requirement | Status | Current evidence / remaining proof |
|---|---|---|
| Active-use focus and break scheduling | Implemented | `Model.observe`, manifest settings, pure tests |
| Timestamp persistence and restart recovery | Partial | Atomic state snapshot exists; suspend/clock-jump and corrupt-state acceptance tests remain |
| Office hours, including overnight | Implemented | Pure overnight test plus manifest-backed configuration; boundary/runtime schedule QA remains |
| Manual pause/resume | Implemented | Service IPC and quick-panel pause action; resume UI/fixture coverage remains |
| Idle detection | Implemented | Wayland idle monitor; runtime transition evidence remains |
| Fullscreen detection | Implemented | Bounded `hyprctl activewindow -j` probe; availability/error state remains implicit |
| Media detection | Implemented | Quickshell MPRIS playback state; detector toggle/configuration remains unexposed |
| Microphone/meeting detection | Partial | PipeWire stream heuristic works locally; communication classification and availability explanation remain |
| Dictation detection | Partial | Omarchy status probe works when installed; capability state and non-polling integration remain |
| Confidence policy, cooldown, maximum delay | Implemented | Pure policy and precedence exist; broader boundary tests remain |
| Bar and anchored quick panel | Implemented | Installed and exercised; state/action/accessibility matrix remains |
| Warning, final chip, break overlay | Implemented | Deterministic fixtures and approved theme-aware break transition |
| Multi-monitor single authority | Implemented | Focused-monitor authority in `Overlay.qml`; hotplug/action tests remain |
| Gentle/Balanced/Focused enforcement | Partial | Action visibility, snooze budget, and consequences UI exist; Focused emergency exit remains incomplete |
| MVP configuration contract | Partial | Core typed manifest values are wired and README documents `omarchy bar set`; sound, output placement, and privacy-reset documentation remain |
| Outcome totals | Partial | Prompted/completed/postponed/skipped/delayed persist and history reset exists; summary UI remains |
| Privacy boundary | Implemented by design | No content capture/title persistence/network calls; release audit remains |
| Deterministic fixtures | Partial | Working/due/paused/postponed/protected/warning/final/break exist; offline/recovery/enforcement variants remain |
| Keyboard and accessibility | Partial | Native controls, break Escape path, and reduced-motion behavior exist; focus-order/name tests remain |
| Theme and bar-position QA | Partial | Native roles and anchored panel implemented; full contrasting-theme/bar-position matrix remains |
| Automated tests and QML review | Partial | Pure model tests exist; test runner, component tests, lint/review gates remain |
| Public packaging | Missing | Manifest validates; license, preview, release README, marketplace metadata, and clean install/remove proof remain |
| Competition submission | Missing | External publication and marketplace submission require final authorization |

## Immediate release sequence

1. Expose and wire every MVP configuration value, including reduced motion and privacy reset.
2. Harden detector availability, persistence recovery, enforcement budgets, and fixture coverage.
3. Complete keyboard/accessibility, automated tests, runtime logs, theme/bar/multi-monitor QA.
4. Produce preview/demo assets, packaging metadata, clean-install proof, and submission materials.

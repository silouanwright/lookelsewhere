# Wayland Break Coach — Pre-build Research

This package defines the product before implementation. The working product name is intentionally generic.

## Verdict

Build a standalone, local-first Wayland service with first-class Hyprland support and an optional Omarchy Shell plugin. Do not build the core as an Omarchy-only plugin.

The differentiated product is not another fixed timer. It is an explainable interruption-policy engine that combines accurate active-use tracking, natural-pause detection, several recovery modalities, and graceful suppression when interruption would be harmful.

## Artifacts

- `competitive-matrix.md` — adversarial market and feature comparison
- `detection-feasibility.md` — meeting, media, dictation, sharing, idle, and fullscreen detection
- `product-spec.md` — exact product, MVP, boundaries, architecture, and milestones
- `state-machine.md` — authoritative runtime states and edge cases
- `omarchy-plugin-audit.md` — existing shell art, services, and plugin patterns to reuse
- `lookaway-capture-checklist.md` — structured Mac application audit
- `lookaway-observations.md` — interaction and settings findings from supplied captures
- `lookaway-public-audit.md` — public documentation/blog feature inventory and disposition
- `design-system.md` — visual language, surfaces, interaction, motion, sound, copy, and accessibility
- `configuration-spec.md` — progressive configuration model, schema outline, polish gates, and usability tests
- `SettingsView.prototype.qml` — exact deferred Quickshell settings prototype from commit `3d7bc50`; retained as non-runtime research material
- `prototype.html` — clickable interaction prototype
- `probes/` — safe, read-only environment probes

## Decision gates before production code

1. Run the probes during a browser video, a call, dictation, screen sharing, fullscreen work, idle, lock, and suspend/resume.
2. Fill in the LookAway capture checklist with screenshots and short recordings.
3. Test the interaction prototype for at least one normal workday.
4. Decide the native overlay toolkit only after proving multi-monitor layer-shell behavior.
5. Treat automatic context detection as confidence-scored evidence, never as an infallible binary signal.

## Research principles

- No medical-treatment or disease-prevention claims.
- The exact 20-20-20 cadence is a preset, not a scientific truth.
- No screen contents, window titles, audio, video, or keystrokes are stored.
- Local-only aggregate history by default.
- Every automatic suppression decision is visible and explainable.
- There is always a safe recovery path if the shell, compositor, daemon, or display topology changes.

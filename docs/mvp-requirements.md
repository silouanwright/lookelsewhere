# Competition MVP Requirements

## Required behavior

### Scheduling

- Count active use toward an editable focus interval; default 20 minutes.
- Show an editable break duration; default 20 seconds.
- Support office hours, including schedules that cross midnight.
- Support temporary pause with an explicit resume time or manual resume.
- Reconstruct state from persisted timestamps after shell reload, restart, suspend, or clock discontinuity.

### Smart Context

- Observe user idle state.
- Observe Hyprland fullscreen state.
- Observe MPRIS playback where players expose it.
- Observe PipeWire microphone/communication activity without recording audio.
- Observe Omarchy dictation state.
- Combine evidence by confidence and policy rather than treating one heuristic as truth.
- Explain the active delay category in plain language.
- Apply a short cooldown after protected context ends, then prefer a natural pause.
- Enforce a configurable maximum delay so breaks cannot disappear indefinitely.

### Interruption flow

- Expose quiet upcoming/due/paused/protected/offline states in the bar.
- Provide a compact native quick panel for status and frequent actions.
- Present a stable top-centered warning before a break.
- Offer `Start now` and policy-allowed postponement.
- Replace the warning with a compact final countdown chip.
- Present the break on configured outputs with exactly one interactive authority.
- Return without requiring a success survey.

### Enforcement

- Provide Gentle, Balanced, and Focused presets.
- Default to Balanced.
- Make preset consequences explicit before selection.
- Preserve an emergency exit in the strongest mode.
- Track prompted, completed, postponed, skipped, and context-delayed outcomes locally.

### Configuration

- Editable focus interval, break duration, office hours, and long-delay cap.
- Context toggles for idle, fullscreen, media, microphone/meeting, and dictation.
- Enforcement preset and postponement budget.
- Sound, output placement, and reduced-motion controls.
- Privacy explanation and local-data reset.

## Quality requirements

- No runtime QML warnings in supported flows.
- Full keyboard operation with visible focus.
- Correct behavior under top, bottom, left, and right bars where the surface is bar-anchored.
- No clipping at available output bounds or supported scale factors.
- Theme-native dark, light/high-contrast, rounded, and sharp-corner behavior.
- Stable geometry across countdown ticks and asynchronous state changes.
- No persistent collection of application or media content metadata.
- Deterministic fixture commands for every material visual state.
- Clean install, disable, update, and removal documentation.

## Release boundary

Features outside this document require an explicit scope decision. A feature is not part of the MVP merely because a settings row or placeholder can be drawn for it.

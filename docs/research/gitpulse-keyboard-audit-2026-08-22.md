# GitPulse Keyboard-First Audit — 2026-08-22

Reference: `AzambekDev/omarchy-gitpulse`, inspected at commit
`be29345` on 2026-08-22.

## What it gets right

- The plugin treats the keyboard as a complete interaction path rather than a
  supplement to pointer controls.
- A visible cursor, Vim-style movement, direct tab keys, action mnemonics, a
  close key, IPC commands, and a documented Hyprland binding make its behavior
  discoverable and scriptable.
- Omarchy's first-party `PanelKeyCatcher` is a sound fit for its selectable
  list rows because it centralizes cursor and activation semantics.

## What should not be copied wholesale

- GitPulse manually establishes focus from a `PopupCard`. Look Elsewhere
  already uses Omarchy's `KeyboardPanel`, which gives its small action surface
  a stronger native focus and dismissal foundation.
- A visual list cursor is useful for a repository list, but would add state and
  noise to Look Elsewhere's compact set of direct actions. Native Tab traversal
  and mnemonic shortcuts are the simpler semantic fit.
- Its monolithic panel and bespoke color treatments are not a model for this
  plugin's component boundaries or theme integration.

## Decisions adopted by Look Elsewhere

- While the quick panel is open: `B` starts a break; `1`, `2`, and `3` select
  the three snooze durations; `P` pauses or resumes; `H` and `O` open history
  and options; and `Q` closes the panel.
- Tab, Backtab, pointer input, accessible button roles, and Escape remain fully
  supported. Mnemonics do not replace standard navigation.
- Pause is disabled during interrupting enforcement, including through IPC, so
  keyboard convenience cannot become a policy bypass.
- README recipes expose optional global actions through unclaimed
  `Super+Alt` chords. The plugin does not mutate Hyprland configuration during
  installation, and users are told how to inspect conflicts first.

## Result

The useful lesson from GitPulse is the completeness of its keyboard contract,
not its exact UI machinery. Look Elsewhere adopts direct, memorable actions and
scriptable IPC while retaining the smaller Omarchy-native architecture that
fits an anchored wellness panel.

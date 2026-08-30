# LookElsewhere Configuration

This is the canonical human-facing configuration reference for LookElsewhere.
The machine-enforced schema and defaults live in [`manifest.json`](manifest.json).
If this document and the manifest ever disagree, the manifest describes what
the installed Omarchy Shell actually accepts and this document should be fixed.

LookElsewhere does not read this file as configuration. Omarchy stores the
active values in `~/.config/omarchy/shell.json`. Change them with:

```bash
omarchy bar set io.github.silouanwright.look-elsewhere <key> <json-value> --json
```

Strings must be passed as JSON strings. For example:

```bash
omarchy bar set io.github.silouanwright.look-elsewhere enforcement '"hardcore"' --json
omarchy bar set io.github.silouanwright.look-elsewhere focusMinutes 25 --json
omarchy bar set io.github.silouanwright.look-elsewhere reducedMotion true --json
omarchy bar set io.github.silouanwright.look-elsewhere reducedTransparency true --json
```

Only values that differ from the defaults need to be stored. Omitting a value
uses the default declared by the plugin manifest.

## Timing and policy

| Key | Default | Accepted values | Meaning |
|---|---:|---|---|
| `focusMinutes` | `20` | Integer `1–180` | Minutes of active screen use between breaks. |
| `breakSeconds` | `20` | Integer `5–600` | Ordinary break duration. |
| `longBreakEvery` | `4` | Integer `0–20` | Make every Nth break long; `0` disables long breaks. |
| `longBreakSeconds` | `180` | Integer `5–3600` | Long-break duration. |
| `enforcement` | `"balanced"` | `"casual"`, `"balanced"`, `"hardcore"` | Casual and Balanced allow skipping; Hardcore makes an active break unskippable. All modes retain bounded snoozing. |
| `maximumDelayMinutes` | `15` | Integer `0–180` | Maximum time protected context may delay a due break. |
| `snoozeBudget` | `3` | Integer `0–10` | Snoozes available during each focus cycle. |

### Enforcement modes

- **Casual:** allows bounded snoozing before a break and skipping during it.
- **Balanced:** the default; currently uses the same snooze and skip permissions
  as Casual.
- **Hardcore:** retains bounded snoozing before a break, but an active break
  cannot be skipped with the button or Escape and ends only when its timer
  completes.

## Break copy

| Key | Default | Accepted values | Meaning |
|---|---|---|---|
| `breakTitle` | `"Look elsewhere"` | String | Short-break title. |
| `breakSubtitle` | `"Let your eyes settle on something distant. Breathe. The screen will still be here."` | String | Short-break guidance. |
| `longBreakTitle` | `"Look elsewhere"` | String | Long-break title. |
| `longBreakSubtitle` | `"Stand up, stretch, and leave the screen for a few minutes."` | String | Long-break guidance. |

## Office hours

| Key | Default | Accepted values | Meaning |
|---|---:|---|---|
| `officeHoursEnabled` | `false` | Boolean | Count active use only during the configured schedule. |
| `officeStart` | `"08:00"` | `HH:MM`, 24-hour time | Beginning of the schedule. |
| `officeEnd` | `"18:00"` | `HH:MM`, 24-hour time | End of the schedule. Earlier end times create an overnight schedule. |

## Planned breaks

Create and edit recurring routines under **Settings → Plans**. Each routine
has a name, local start time, duration, selected weekdays, and enabled state.
LookElsewhere stores the complete bounded schedule in `plannedBreaks`; the
settings panel is the recommended editor.

Planned breaks run independently of Office Hours, but still respect global
pause, protected context, and maximum delay. Time already spent away after the
scheduled start is credited toward the planned duration. A nearby ordinary eye
break is coalesced instead of interrupting again, and **Skip Today** is always
available, including in Hardcore mode. LookElsewhere accepts at most eight
routines and disables later routines whose schedules overlap.

| Key | Default | Accepted values | Meaning |
|---|---:|---|---|
| `plannedBreaks` | `"[]"` | JSON-encoded array of up to 8 routines | Recurring local-time planned breaks. Use the Plans panel unless scripting. |

```json
[{"id":"lunch","name":"Lunch","startMinute":720,"durationMs":1800000,"days":[1,2,3,4,5],"enabled":true}]
```

`startMinute` is minutes after local midnight. Weekdays use JavaScript day
numbers: Sunday is `0`, Monday is `1`, through Saturday `6`.

## Smart context

| Key | Default | Accepted values | Meaning |
|---|---:|---|---|
| `idleDetection` | `true` | Boolean | Pause active-use accounting while the user is away. |
| `recentInputDetection` | `true` | Boolean | Hold the final ten seconds while keyboard or pointer input continues. Wayland cannot distinguish the two. |
| `fullscreenDetection` | `true` | Boolean | Delay a due break while the focused window is fullscreen. |
| `mediaDetection` | `true` | Boolean | Delay for focused-app MPRIS playback. See the README limitation about audio/video classification. |
| `microphoneDetection` | `true` | Boolean | Delay while PipeWire reports an active microphone stream; audio is never recorded. |
| `screenSharingDetection` | `true` | Boolean | Delay when an active PipeWire stream explicitly identifies screen sharing or recording. |
| `dictationDetection` | `true` | Boolean | Delay while Omarchy Voxtype dictation is active. |
| `pauseDuringSteamGames` | `true` | Boolean | When optional Sundown is connected, pause active-time accounting while it detects a Steam or Proton game. Without Sundown, focused-window protection remains the fallback. |
| `protectedApps` | `"steam"` | Comma-separated application IDs | Delay due breaks while listed applications are focused. Add or remove the focused application from **Settings → Context**, or edit the list directly. `steam` also matches `steam_app_<id>` game windows. |

## Presentation

| Key | Default | Accepted values | Meaning |
|---|---:|---|---|
| `reducedMotion` | `false` | Boolean | Remove animated movement and soft-focus reveals. |
| `reducedTransparency` | `false` | Boolean | Remove decorative patterns, soft-focus effects, and translucent break backdrops. |
| `outputMode` | `"all"` | `"all"`, `"focused"` | Show interruptions on every output or only the focused output. |
| `displayMode` | `"icon-and-time"` | `"icon"`, `"time"`, `"icon-and-time"` | Bar-widget presentation. Vertical bars use the icon. |
| `panelPattern` | `"off"` | `"off"`, `"topography"`, `"graph-paper"`, `"wiggle"`, `"bank-note"`, `"diagonal-lines"` | Optional patterned background for the plugin panel. |
| `showKeyboardHints` | `false` | Boolean | Show action-key badges whenever the panel opens. |

## Sound

| Key | Default | Accepted values | Meaning |
|---|---:|---|---|
| `soundEnabled` | `true` | Boolean | Master switch for both bundled/custom break cues. |
| `soundVolume` | `65` | Integer `0–100` | LookElsewhere cue volume; system output volume remains the final ceiling. |
| `startSoundEnabled` | `true` | Boolean | Play a cue when a break begins. |
| `completionSoundEnabled` | `true` | Boolean | Play a cue just before a break finishes. |
| `startSoundPath` | `""` | Absolute path, `~/` path, or empty | Custom start cue; empty uses the bundled cue. |
| `completionSoundPath` | `""` | Absolute path, `~/` path, or empty | Custom completion cue; empty uses the bundled cue. |

## Panel shortcuts

Shortcut values accept one letter, one digit, `?`, `F1–F12`, or a chord using
Ctrl, Alt, Shift, or Meta. Invalid or conflicting values fall back to the
defaults. Tab, Shift+Tab, Enter, Space, and Escape remain fixed accessibility
conventions.

| Key | Default | Action |
|---|---:|---|
| `shortcutBreakNow` | `"B"` | Start a break. |
| `shortcutSnooze1` | `"1"` | Snooze one minute. |
| `shortcutSnooze5` | `"2"` | Snooze five minutes. |
| `shortcutSnooze15` | `"3"` | Snooze fifteen minutes. |
| `shortcutSkipToday` | `"S"` | Skip the active planned routine for today. |
| `shortcutPause` | `"P"` | Pause or resume scheduling. |
| `shortcutHistory` | `"H"` | Open break history. |
| `shortcutOptions` | `"O"` | Open options. |
| `shortcutEdit` | `"E"` | Open the configuration file from Options. |
| `shortcutGeneralTab` | `"G"` | Open General settings. |
| `shortcutBreaksTab` | `"R"` | Open Breaks settings. |
| `shortcutPlansTab` | `"L"` | Open Plans settings. |
| `shortcutContextTab` | `"C"` | Open Context settings. |
| `shortcutExperienceTab` | `"X"` | Open Experience settings. |
| `shortcutClose` | `"Q"` | Close the panel. |
| `shortcutHints` | `"?"` | Toggle visible shortcut badges. |

## Complete default reference

This JSONC block is documentation, not a second configuration file. It shows
the complete default value set in one copyable shape:

```jsonc
{
  // Timing and policy
  "focusMinutes": 20,
  "breakSeconds": 20,
  "longBreakEvery": 4,
  "longBreakSeconds": 180,
  "enforcement": "balanced",
  "maximumDelayMinutes": 15,
  "snoozeBudget": 3,

  // Recurring local-time routines; edit under Settings → Plans
  "plannedBreaks": "[]",

  // Break copy
  "breakTitle": "Look elsewhere",
  "breakSubtitle": "Let your eyes settle on something distant. Breathe. The screen will still be here.",
  "longBreakTitle": "Look elsewhere",
  "longBreakSubtitle": "Stand up, stretch, and leave the screen for a few minutes.",

  // Office hours
  "officeHoursEnabled": false,
  "officeStart": "08:00",
  "officeEnd": "18:00",

  // Smart context
  "idleDetection": true,
  "recentInputDetection": true,
  "fullscreenDetection": true,
  "mediaDetection": true,
  "microphoneDetection": true,
  "screenSharingDetection": true,
  "dictationDetection": true,
  "pauseDuringSteamGames": true,
  "protectedApps": "steam",

  // Presentation
  "reducedMotion": false,
  "reducedTransparency": false,
  "outputMode": "all",
  "displayMode": "icon-and-time",
  "panelPattern": "off",
  "showKeyboardHints": false,

  // Sound
  "soundEnabled": true,
  "soundVolume": 65,
  "startSoundEnabled": true,
  "completionSoundEnabled": true,
  "startSoundPath": "",
  "completionSoundPath": "",

  // Panel shortcuts
  "shortcutBreakNow": "B",
  "shortcutSnooze1": "1",
  "shortcutSnooze5": "2",
  "shortcutSnooze15": "3",
  "shortcutSkipToday": "S",
  "shortcutPause": "P",
  "shortcutHistory": "H",
  "shortcutOptions": "O",
  "shortcutEdit": "E",
  "shortcutGeneralTab": "G",
  "shortcutBreaksTab": "R",
  "shortcutPlansTab": "L",
  "shortcutContextTab": "C",
  "shortcutExperienceTab": "X",
  "shortcutClose": "Q",
  "shortcutHints": "?"
}
```

## Inspecting and resetting local state

Configuration and private scheduler state are separate. Inspect diagnostics or
reset only the local schedule/history with:

```bash
omarchy-shell look-elsewhere diagnostics
omarchy-shell look-elsewhere resetLocalData
```

`resetLocalData` does not change any Omarchy configuration value.

# Privacy and Trust Model

## Promise

LookElsewhere observes the minimum local signals needed to time interruptions. It does not build an activity history, inspect content, require an account, or send telemetry.

## Allowed transient evidence

- Idle/active state and durations
- Fullscreen state and coarse application identifier where needed for a local rule
- MPRIS playback status and player identity where needed for classification
- Coarse, bounded PipeWire role, capture-audio, and application-identity fields
  required to infer microphone, meeting, camera, sharing, or video activity
- Omarchy dictation active/inactive state
- Current output/workspace state required for surface placement

## Prohibited persistence and default presentation

- Window or media titles
- URLs, document names, meeting names, contact identities
- Audio, video, camera frames, screenshots, transcripts, or clipboard contents
- A timeline of applications used
- Raw PipeWire or process snapshots
- Analytics identifiers or remote event logs

Persist user configuration only through Omarchy's `shell.json`. The plugin state file contains semantic state, timestamps needed for recovery, aggregate break outcomes, and optional coarse detector diagnostics that contain no content metadata.

## Process execution

- Prefer native Quickshell services over external commands.
- Use argument arrays, never data-bearing shell command construction.
- Bound execution time and prevent overlapping requests.
- Redact or avoid sensitive stdout/stderr.
- Cap state and compositor input before it crosses into QML. State reads stop
  at 64 KiB; active-window output stops at 64 KiB and is reduced to a bounded
  application identifier plus one fullscreen boolean.
- Never expose the complete application-controlled PipeWire property map to
  QML. Active node reads stop at 64 KiB and the complete request stops at 1.5
  seconds, then retain only allowlisted roles, one capture boolean, and bounded
  application identifiers.
- Do not request elevated privileges.

## User control

- Every detector can be disabled independently.
- Smart Context explanations identify the category in use.
- Local history can be reset.
- A diagnostics view describes signals without exposing content.
- Failure to observe a signal degrades visibly and safely; it does not silently expand observation.

## Threat considerations

Plugins run unsandboxed inside the user’s long-lived Omarchy Shell process.
Dependencies and external commands therefore expand the trust boundary.
LookElsewhere minimizes dependencies, has no install hook, documents its
commands, and does not require network access at runtime.

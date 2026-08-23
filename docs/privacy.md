# Privacy and Trust Model

## Promise

LookElsewhere observes the minimum local signals needed to time interruptions. It does not build an activity history, inspect content, require an account, or send telemetry.

## Allowed transient evidence

- Idle/active state and durations
- Fullscreen state and coarse application identifier where needed for a local rule
- MPRIS playback status and player identity where needed for classification
- PipeWire node/stream properties required to infer microphone or communication activity
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
- Do not request elevated privileges.

## User control

- Every detector can be disabled independently.
- Smart Context explanations identify the category in use.
- Local history can be reset.
- A diagnostics view describes signals without exposing content.
- Failure to observe a signal degrades visibly and safely; it does not silently expand observation.

## Threat considerations

Plugins run unsandboxed inside the user’s long-lived Omarchy Shell process. Dependencies and external commands therefore expand the trust boundary. The competition MVP should minimize dependencies, avoid install hooks, document all commands, and keep network access unnecessary.

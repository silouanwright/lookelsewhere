# Upstream Opportunities Exposed by LookElsewhere

This document records platform boundaries encountered while building
LookElsewhere. It distinguishes generally useful upstream work from application
heuristics, local hardware failures, and features that belong in this plugin.

## Priority summary

| Priority | Opportunity | Primary upstream |
|---|---|---|
| P0 | Current-item audio/video types | MPRIS, Chromium, Firefox, media players |
| P0 | Shared privacy-safe context service | Omarchy Shell |
| P1 | Reliable shutdown and reload lifecycle | Quickshell |
| P1 | Resolved typed plugin settings | Omarchy Shell |
| P1 | Manifest-generated settings UI | Omarchy Shell |
| P1 | First-class plugin keybindings | Omarchy |
| P1 | Stable anchored-popover controller | Omarchy Shell |
| P1 | Standard meeting, sharing, and recording state | XDG portals / desktop ecosystem |
| P1 | Bounded file and process input for QML | Quickshell |
| P2 | Public lock-service action | Omarchy Shell |
| P2 | Keyboard-complete popup controls | Omarchy Shell |
| P2 | Richer Voxtype status and audio discovery | Voxtype / Omarchy |
| Research | Privacy-safe recent-input categories | Wayland compositors / protocol ecosystem |

Priorities describe value to the wider plugin ecosystem, not requirements for
shipping LookElsewhere.

## 1. Current-item audio/video types

**Problem.** MPRIS 2.2 exposes playback state, application identity, controls,
and generic metadata, but it does not identify whether the current item contains
audio, video, or both. `SupportedMimeTypes` describes player capabilities rather
than the active item. Chromium exports browser media sessions without a video
track signal.

**Current workaround.** LookElsewhere treats playback as video only when the
MPRIS player's application matches the focused Hyprland application. This
ignores background music but can misclassify a focused music player or tab.

**Proposed upstream work.**

1. Add optional current-item stream information to MPRIS, preferably something
   equivalent to `mpris:mediaTypes = ["audio", "video"]` rather than relying on
   a MIME type.
2. Have Chromium and Firefox map their internal media-session stream state to
   that metadata and emit `PropertiesChanged` when it changes.
3. Have mpv, VLC, and other exporters publish it from decoded track state.
4. Let consumers prefer the standardized field and retain heuristics only for
   older exporters.

Quickshell already exposes the raw MPRIS metadata map, so it does not need a
blocking patch. A typed convenience property could follow standardization.

**Unlocks.** Reliable video-aware break deferral, power policy, presence, status,
and automation across Linux desktops.

References: [MPRIS Player](https://specifications.freedesktop.org/mpris/latest/Player_Interface.html),
[MPRIS metadata](https://specifications.freedesktop.org/mpris/latest/Track_List_Interface.html),
[Chromium MPRIS](https://chromium.googlesource.com/chromium/src/+/b9c645c0b167a38b8f93b6c9e9f5a6a2f3e854ae/ui/base/mpris/mpris_service_impl.cc).

## 2. Shared privacy-safe context service

**Problem.** Omarchy already observes media, dictation, recording, idle, and
other shell state, but third-party plugins lack a documented service-to-service
contract. Each plugin must rediscover processes, PipeWire nodes, MPRIS players,
and compositor state.

**Current workaround.** LookElsewhere owns separate Quickshell detectors and
normalizes them into coarse evidence.

**Proposed upstream work.** Expose a stable read-only service containing coarse
booleans and availability such as `idle`, `mediaPlaying`, `microphoneActive`,
`dictationActive`, `recording`, and `screenSharing`. Do not expose titles,
participants, transcripts, URLs, or captured content. Document signal lifetime,
reload behavior, and capability discovery.

**Unlocks.** Consistent privacy behavior, fewer background probes, and reusable
context awareness across wellness, presence, notification, and automation
plugins.

## 3. Reliable shutdown and reload lifecycle

**Problem.** Quickshell does not currently provide a shutdown/reload callback
reliable enough for the plugin to guarantee a final state flush before shell
replacement.

**Current workaround.** LookElsewhere checkpoints state every five seconds,
which bounds but does not eliminate a visible countdown rollback after restart.

**Proposed upstream work.** Provide documented `aboutToReload` and
`aboutToQuit` signals with a bounded synchronous completion phase, plus a clear
contract for plugin object destruction during reload.

**Unlocks.** Exact persistence for timers and other resident plugin state with
less disk activity.

## 4. Resolved typed plugin settings

**Problem.** Omarchy injects values explicitly present in a widget's
`shell.json` entry but does not merge manifest defaults before delivering the
settings object.

**Current workaround.** LookElsewhere rebuilds configuration from defaults on
every reconciliation, then applies supplied values and validation.

**Proposed upstream work.** Resolve manifest defaults and validate declared
types centrally before exposing an immutable settings snapshot to plugins.
Preserve access to raw values only for migration tooling.

**Unlocks.** Smaller plugins, consistent validation, safer setting removal, and
fewer stale-value bugs.

## 5. Manifest-generated settings UI

**Problem.** Plugin manifests already declare keys, types, labels, ranges,
options, defaults, and descriptions, but Omarchy does not automatically render
that schema as a graphical settings surface.

**Current workaround.** LookElsewhere provides its own categorized settings
pages. They write through Omarchy's persistence API and consume the same
manifest-backed contract, but the UI and schema mapping remain plugin-owned.

**Proposed upstream work.** Render a native Omarchy settings page from the
manifest schema, supporting booleans, numbers, enums, durations, paths,
shortcuts, reset-to-default, validation, and optional grouping. Allow a plugin
to add a custom page only when its configuration cannot be represented by the
schema.

**Unlocks.** Polished configuration for every plugin without bespoke settings
applications or theme drift.

## 6. First-class plugin keybindings

**Problem.** A plugin cannot safely request an optional global Hyprland binding
with installation consent and conflict detection.

**Current workaround.** LookElsewhere documents commands users can add
manually. Panel-local shortcuts remain fully functional once the panel has
focus.

**Proposed upstream work.** Add manifest declarations for suggested global
actions and default chords. During installation or settings changes, show the
binding, detect conflicts, allow reassignment, and write configuration only
after explicit approval.

**Unlocks.** Truly keyboard-first plugins without silently modifying user
configuration.

## 7. Stable anchored-popover controller

**Problem.** Plugin panels are reconstructed during bar-position and theme
changes. Transient panel-owned IPC handlers can remain briefly authoritative,
and plugins must manually coordinate focus and mutual exclusion with other bar
popouts.

**Current workaround.** LookElsewhere keeps IPC authority in the resident bar
widget, reinjects panel dependencies after reconstruction, and participates in
the shell's current popout coordination behavior.

**Proposed upstream work.** Provide a host-owned controller for anchored popup
creation, placement, focus acquisition, Escape behavior, mutual exclusion,
reconstruction, and keyboard activation. Give plugins stable open/close/toggle
actions independent of the transient visual instance.

**Unlocks.** Reliable popovers with much less lifecycle code and fewer stale
handler or focus defects.

## 8. Standard meeting, sharing, and recording state

**Problem.** Linux has no authoritative cross-desktop signal for “in a meeting,”
“sharing the screen,” or “recording.” PipeWire roles are useful but inconsistently
set. The ScreenCast portal manages sessions created by its caller and does not
promise a global registry of other applications' sessions.

**Current workaround.** LookElsewhere combines microphone, fullscreen,
dictation, application, and PipeWire evidence with confidence thresholds. It
cannot claim exact semantics.

**Proposed upstream work.** Define a privacy-preserving portal or desktop status
protocol that publishes coarse activity and availability without identifying
participants, meeting titles, captured surfaces, or content. Portal backends
should mediate access and make false/stale state behavior explicit.

**Unlocks.** Dependable notification suppression, presence, wellness timing,
and recording indicators across desktops.

References: [ScreenCast portal](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html)
and [PipeWire properties](https://pipewire.pages.freedesktop.org/pipewire/page_man_pipewire-props_7.html).

## 9. Public lock-service action

**Problem.** Plugins lack a documented service action for invoking Omarchy's
lock flow. Shell-command indirection couples plugins to command names and makes
completion semantics unclear.

**Current workaround.** LookElsewhere enforces Hardcore breaks inside its
layer-shell surface. Layer-shell keyboard interactivity cannot override every
compositor or session action by design.

**Proposed upstream work.** Expose a stable, permission-aware lock action and a
read-only locked-state signal through the shell service layer.

**Unlocks.** Stronger optional break enforcement and safe lock integration for
other security- or privacy-adjacent plugins.

## 10. Richer Voxtype status and audio discovery

**Problem.** On the validation machine, `voxtype record start` failed while
building its ALSA stream and immediately returned to `idle`. The status stream
did not distinguish an available idle recorder from an unavailable or failed
one.

**Current workaround.** LookElsewhere consumes `omarchy-voxtype-status` as an
idle/recording stream and reports only coarse capability. Failed audio setup
cannot be represented accurately.

**Proposed upstream work.** Define states such as `idle`, `recording`,
`unavailable`, and `error`, with a stable coarse reason code. Improve default
device discovery through the active PipeWire/WirePlumber graph where practical,
while keeping detailed errors in logs.

**Unlocks.** Honest dictation availability, better diagnostics, and fewer audio
device failures for Voxtype itself.

## 11. Privacy-safe recent-input categories

**Problem.** Wayland idle notification reports whether recent input occurred,
not whether that input was typing, pointing, or dragging. Ordinary clients
correctly cannot observe global keys or pointer coordinates.

**Current workaround.** During the final ten seconds, LookElsewhere uses a
one-second idle monitor and labels recent keyboard-or-pointer activity as
`Typing..`. It never reads or stores key values or coordinates.

**Potential upstream work.** Research a compositor-mediated signal exposing
only coarse recent-input categories and timestamps, with no key values,
coordinates, target surfaces, or history. This should proceed only with a clear
security review; the existing approximation is preferable to weakening
Wayland's input isolation.

**Unlocks.** More accurate “finish typing or dragging” behavior while retaining
privacy.

## 12. Bounded file and process input for QML

**Problem.** `FileView.text()` and `StdioCollector` accumulate complete inputs
before application code can validate their size. A long-lived shell plugin
cannot safely ingest replaceable files or application-influenced command output
without bounding the producer before QML receives it.

**Current workaround.** LookElsewhere reads state through a descriptor-bound
helper that uses `O_NOFOLLOW | O_NONBLOCK`, verifies regular-file type and
current-user ownership with `fstat`, and emits at most 64 KiB. `FileView`
remains write-only. Its `hyprctl activewindow` fallback caps the JSON stream
and uses `jq` to return only a bounded application identifier and fullscreen
boolean.

**Proposed upstream work.** Add byte-limited file reads and process collectors
that stop or reject input at a caller-defined maximum before allocating the
complete payload. Expose truncation as an explicit error. A typed, bounded
Hyprland active-window service would remove this plugin's subprocess fallback
entirely.

**Unlocks.** Safer parsing in every resident QML plugin, fewer helper processes,
and a reusable answer to untrusted or unexpectedly large local input.

## 13. Keyboard-complete popup controls

**Problem.** Omarchy's shared dropdown does not select an open item with Space,
and plugins must assemble their own cross-control arrow navigation, focus
restoration, and Escape behavior. Similar-looking controls can therefore have
different keyboard contracts.

**Current workaround.** LookElsewhere wraps or vendors the smallest necessary
controls and gives each one an `activate()` contract. Its settings page owns one
ordered navigation model, while shortcuts remain scoped to the focused popup
window.

**Proposed upstream work.** Make shared toggles, dropdowns, number fields,
segmented controls, and popup navigation fully keyboard-complete: visible focus,
Tab and reverse Tab, directional movement, Enter and Space activation, Escape
restoration, and accessibility metadata. Document a standard ordered-navigation
composition for plugin panels.

**Unlocks.** Consistent keyboard-first plugins without each author rebuilding
focus and activation semantics.

## What should not move upstream

The following remain LookElsewhere policy or optional adapters:

- break timing, enforcement modes, snooze budgets, and wellness copy;
- meeting-vendor and application-class databases;
- browser-site semantics and tab inspection;
- confidence thresholds and maximum-delay policy;
- medical or health-effect claims.

Local absence of an audio input node and lack of physical mixed-scale monitors
are validation-environment constraints, not upstream defects. Browser extensions
and player-specific adapters remain appropriate when a portable standard cannot
provide exact application semantics.

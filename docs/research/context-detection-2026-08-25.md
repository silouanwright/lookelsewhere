# Context Detection Research, 2026-08-25

This is the source of truth for LookElsewhere's Linux context detectors. It
records what the platform can prove, what remains heuristic, what data crosses
into QML, and which gaps belong upstream.

## Tested platform

- Omarchy 4.0.0
- Hyprland 0.56.2
- Quickshell 0.3.0.r20.g28771c7
- PipeWire 1.6.8 and WirePlumber 0.5.15
- xdg-desktop-portal 1.22.1
- xdg-desktop-portal-hyprland 1.4.1
- Qt 6.11.1

The results are architectural, but exact availability and metadata quality vary
by application and distribution version.

## Decision matrix

| Context | Primary signal | Confidence | Current behavior | Known limit |
|---|---|---:|---|---|
| Away | Wayland idle notification | High | Pauses active-time accounting | Idle inhibitors and compositor policy can differ |
| Recent typing/work | Short idle-notify window | Medium | Holds the final ten seconds while input remains active | Wayland intentionally does not reveal whether input was keyboard or pointer |
| Fullscreen | Quickshell Hyprland toplevel; bounded `hyprctl` fallback for XWayland | High | Delays a due break | Fullscreen does not prove video or a meeting |
| Protected app | Focused app ID matched against user configuration | High | Delays a due break | Window identity varies across native Wayland and XWayland apps |
| Focused media | MPRIS playback plus focused-player identity | Medium | Delays while the focused player is playing | Browsers do not expose whether the active media session contains video |
| Microphone capture | Active PipeWire links plus bounded `media.class` / `media.category` evidence | High when declared | Delays and reports Mic/Meeting | A client that omits or falsifies standard properties can evade or confuse classification |
| Meeting | PipeWire `media.role=Communication`, or microphone capture plus fullscreen | High / medium | Delays and reports Meeting | No cross-desktop meeting roster or authoritative meeting state exists |
| Camera | PipeWire `media.role=Camera` | High when declared | Delays and reports Camera | Role adoption is application-dependent |
| Screen sharing / recording | PipeWire `media.role=Screen` | High when declared | Delays and reports Sharing | Portal sessions do not consistently expose this role to ordinary graph observers |
| Video | Focused PipeWire `media.role=Movie`; otherwise focused MPRIS playback | High / medium | Reports Video only for an explicit role; generic MPRIS remains Media | Chromium and Firefox omit current-item media type today |
| Dictation | `omarchy-voxtype-status` | High | Delays and reports Dictation | The status stream cannot fully describe audio-device failure |

## PipeWire findings

PipeWire defines semantic `media.role` values including `Movie`, `Music`,
`Camera`, `Screen`, and `Communication`, and `media.category` values including
`Playback`, `Capture`, and `Duplex`. These are useful declarations, not
guaranteed truth.

Live probes established two important behaviors:

1. A real microphone reader created `Stream/Input/Audio` with
   `media.category=Capture`. The former QML-only test inferred capture from
   untracked audio objects and was less reliable.
2. Chromium playing YouTube created `Stream/Output/Audio` with no `media.role`
   or `media.category`. PipeWire therefore cannot distinguish that video from
   browser music on this machine.

Quickshell exposes `PwNode.properties` only after `PwObjectTracker` binds a
node. Its implementation copies the complete PipeWire dictionary into a
`QMap<QString, QString>` and then builds a complete `QVariantMap` for QML.
Applications may place private titles and other unneeded values in that map.
LookElsewhere deliberately does not use this API for classification.

Instead, `tools/pipewire-evidence` accepts at most 32 numeric stream-node IDs
taken from active, explicitly tracked Quickshell link groups. Device and filter
endpoints are excluded before the cap. It invokes `/usr/bin/pw-dump` without a shell,
caps each node at 64 KiB and the complete request at 1.5 seconds, validates JSON
shape, and emits only:

- an allowlisted semantic role;
- a capture-audio boolean;
- at most four application identity candidates, each capped at 256 characters.

Titles, artists, URLs, node descriptions, audio, and video never enter QML.
The helper runs on active-link topology changes rather than polling.
PipeWire clients conventionally set these semantic properties when creating a
node. A client that mutates them without relinking may remain stale until the
next topology change; periodic full-graph polling would cost more and still
would not make undeclared metadata authoritative.

## MPRIS findings

MPRIS 2.2 exposes playback state, player identity, controls, and a generic
metadata map. `SupportedMimeTypes` describes what the player can open, not the
current item. The metadata map permits Xesam fields, and historical KDE notes
mention `xesam:mimeType`, but it is optional and not a dependable current-item
contract.

Observed Chromium metadata contained track ID, title, artist, album, art, and
length, but no MIME or media-type field. Chromium's current MPRIS service and
Firefox's `MPRISServiceHandler.cpp` likewise build metadata without
`xesam:mimeType`. Firefox currently emits track ID, title, album, artist, art,
URL, and length.

Consequently LookElsewhere retains the conservative rule: playing MPRIS media
delays a due break only when that player's application matches the focused
application. It calls this generic state `Media`, not `Video`. Explicit
PipeWire `Movie` evidence may upgrade the label to `Video`.

## Portals and screen sharing

The ScreenCast portal creates sessions on behalf of its caller. Session object
paths and lifecycle are sender-scoped; the public API is not a global observer
registry. Adding a universal observer would introduce access-control and
privacy questions because captured surfaces and requesting identities can be
sensitive.

For Hyprland, the narrowest useful upstream is already proposed in
[XDPH issue #331](https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/331):
an IPC surface that can list active screencopy sessions. LookElsewhere needs
only an event-driven coarse active/count signal. It does not need region,
surface title, or application identity.

Non-portal screencopy also exists. Hyprland issue #9915 and its implementation
show why a portal-only status is not a universal recording detector. A future
compositor-level status should distinguish portal and non-portal capture while
exposing no captured content.

## Upstream work

### Existing issues to support, not duplicate

1. **XDPH #331:** request an event-driven coarse screencopy active/count signal
   in addition to administrative list/end commands.
2. **Quickshell #407:** expose actual PipeWire node running/suspended state.
   Active link groups work for LookElsewhere today, but node state is useful
   corroborating evidence and avoids consumer-specific workarounds.

### New Quickshell issue worth drafting

**Title:** Expose typed standard PipeWire node properties without copying the
complete property map into QML

Proposed API: read-only typed fields such as `mediaRole`, `mediaCategory`, and
bounded `applicationId`, populated directly with `spa_dict_lookup()` during
node updates. Keep `properties` for advanced callers, but ordinary shells
should not need to materialize private, application-controlled metadata just
to classify a stream.

Acceptance criteria:

- values have documented maximum lengths or remain native typed strings with a
  clear allocation contract;
- change signals fire when the corresponding PipeWire property changes;
- fields are available only for a tracked node, consistent with current node
  lifecycle;
- no media title, URL, artist, or arbitrary dictionary entry is copied as a
  side effect of reading a semantic field.

### Browser/MPRIS issues worth drafting

Chromium and Firefox already know whether the selected media session has audio
and video tracks. Ask each project to publish a privacy-safe current-item media
type through MPRIS and update it with `PropertiesChanged`. A small standardized
field such as `mpris:mediaTypes=["audio","video"]` is clearer than inferring
from a container MIME type. Standardization should be discussed with MPRIS
before browser-specific keys are shipped.

### Do not open yet

Do not open a generic xdg-desktop-portal “let every app observe all screen
shares” issue until access control and privacy semantics are designed. The
backend/compositor-local XDPH path is narrower and already has a maintainer
discussion.

## Sources

- [PipeWire properties](https://pipewire.pages.freedesktop.org/pipewire/page_man_pipewire-props_7.html)
- [PipeWire dictionary API](https://docs.pipewire.org/group__spa__dict.html)
- [WirePlumber role policy](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/features.html)
- [MPRIS Player interface](https://specifications.freedesktop.org/mpris/latest/Player_Interface.html)
- [MPRIS metadata map](https://specifications.freedesktop.org/mpris/latest/Track_List_Interface.html)
- [Chromium MPRIS service](https://chromium.googlesource.com/chromium/src/+/main/components/mpris/mpris_service.cc)
- [Firefox MPRIS service](https://searchfox.org/firefox-main/source/widget/gtk/MPRISServiceHandler.cpp)
- [ScreenCast portal](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.ScreenCast.html)
- [XDPH #331](https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/331)
- [Quickshell #407](https://github.com/quickshell-mirror/quickshell/issues/407)
- [Hyprland #9915](https://github.com/hyprwm/Hyprland/issues/9915)

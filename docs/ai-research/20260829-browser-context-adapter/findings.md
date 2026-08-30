# Findings: Browser Context Adapter

## Conclusion

An optional browser extension would materially improve LookElsewhere's browser
context accuracy. It can distinguish a playing `<video>` from generic audible
media, tell whether the relevant tab/window is foreground, detect muted video,
and observe ordinary page Picture-in-Picture. The current MPRIS/PipeWire path
cannot make those distinctions reliably.

## Reusable Sundown work

Sundown already proves the correct system boundary on this machine:

- dependency-free Manifest V3 extension;
- event-driven updates plus a bounded five-second reconciliation heartbeat;
- focused-window and active-tab checks;
- native messaging to a local authoritative process;
- versioned, normalized, bounded messages;
- no extension-supplied elapsed-time authority.

LookElsewhere should reuse that architecture, not Sundown's website-budget
policy. A browser adapter should emit only coarse facts such as
`videoPlaying`, `videoVisible`, `pictureInPicture`, and `browserFocused`.
It should never send URLs, titles, page text, media names, or frames.

## Detection ladder

1. A content script observes `<video>` elements and their `playing`, `pause`,
   `ended`, `emptied`, and visibility changes.
2. The service worker combines that fact with the active tab and focused browser
   window. `tabs.Tab.active` alone is insufficient because its window may not be
   focused.
3. `tabs.Tab.audible` remains corroborating evidence only: Chrome defines it as
   recent sound, not video, and it can remain true for muted or audio-only media.
4. Picture-in-Picture is a separate positive signal where the browser exposes
   it. An iframe-owned or browser-triggered PiP surface needs explicit testing.
5. LookElsewhere's existing MPRIS/PipeWire/app/fullscreen evidence remains the
   fallback for unsupported browsers and native applications.

## Product boundary

The adapter should be optional precision, not a requirement for core break
scheduling. Marketplace installation cannot currently install a native host and
managed browser extension automatically, so this is a companion package with a
clear unavailable state. Chromium should be first because Sundown already has a
working local installation and transport path.

The smallest useful first release detects only foreground playing video and
PiP. Meeting/WebRTC, screen sharing, arbitrary custom players, cross-origin
iframes, Firefox packaging, and browser-health enforcement should wait for
separate evidence.


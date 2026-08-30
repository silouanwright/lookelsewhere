# Optional Chromium Integration

LookElsewhere's standard MPRIS and PipeWire detection requires no browser
extension. The optional Chromium integration adds direct, coarse detection for:

- playing foreground video, including muted video;
- paused and buffering transitions;
- playing Picture-in-Picture video, even when Chromium is not focused.

It does not inspect or transmit URLs, titles, page text, media names, browsing
history, audio, video frames, keys, or pointer coordinates.

## Install

From the installed LookElsewhere directory, run:

```bash
~/.config/omarchy/plugins/io.github.silouanwright.look-elsewhere/tools/install-browser-integration
```

Then restart Chromium. Omarchy's existing `chromium-flags.conf` extension list
loads LookElsewhere on the next launch; Developer Mode and manual extension UI
steps are not required.

The installer registers a user-level Chromium native-messaging host and adds
the extension directory to the user's Omarchy-managed Chromium flags. It does
not modify Chromium policy or system-owned files. Remove that directory from
the `--load-extension` line in `~/.config/chromium-flags.conf` to return to
standard detection.

## Status

The Context settings page exposes the active mode:

- **Standard:** system MPRIS and PipeWire signals are active; no extension has
  connected during this shell session.
- **Enhanced:** a fresh extension heartbeat is providing browser video state.
- **Unavailable:** the extension connected earlier but its heartbeat expired;
  system detection remains active.

## Data path and trust boundary

The content script reduces each frame to three values: video state, visual
presence, and Picture-in-Picture state. The service worker combines those with
whether Chromium is focused. A Python standard-library native host caps each
message at 16 KiB, validates and allowlists the fields, and forwards one JSON
line to a Quickshell-owned Unix socket. QML validates the same protocol again,
rejects stale sequence numbers, and expires evidence after 12 seconds.

The extension requests access to HTTP and HTTPS pages because a content script
cannot observe HTML video elements without page access. Its only extension API
permission is `nativeMessaging`; it does not request the sensitive `tabs`,
history, storage, web-request, or clipboard permissions.

## Deliberate limits

- Chromium is the only supported browser in this first release.
- Playing video protects a due break only when its tab is foreground and the
  browser window is focused, or while Picture-in-Picture is playing.
- Background tabs, paused video, and buffering video do not protect the timer.
- Browser meeting detection remains out of scope; PipeWire microphone,
  communication, camera, and screen-sharing signals continue to cover it.
- The extension is loaded from LookElsewhere's installed directory rather than
  a browser store until a trustworthy packaged distribution path is justified.

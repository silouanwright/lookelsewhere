# Gaps: Browser Context Adapter

- Verify Amazon Prime Video, YouTube, Twitch, muted playback, buffering, paused
  playback, background tabs, minimized windows, full-screen video, and PiP on
  native Wayland Chromium.
- Determine whether Prime's player exposes a normal `<video>` element to an
  isolated content script despite DRM. DRM protects media bytes; it does not
  necessarily hide the element, but this must be measured.
- Test video elements inside same-origin and cross-origin iframes with
  `all_frames`; do not infer support from top-level pages.
- Decide whether to extract Sundown's sensor into a neutral browser-context
  companion only after the first LookElsewhere prototype proves shared code is
  real rather than speculative.
- Design extension/native-host health reporting before allowing a missing
  adapter to silently downgrade a user-selected strict browser policy.


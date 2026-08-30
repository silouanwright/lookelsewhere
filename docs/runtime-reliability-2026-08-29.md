# Runtime Reliability Closeout — 2026-08-29

## Countdown

- The scheduler derives time from wall-clock deadlines; presentation cannot
  extend a focus interval or break.
- An ordinary one-second change keeps the rolling animation. A missed sample
  or larger reset snaps directly to the current authoritative value rather
  than replaying stale seconds.
- Component tests cover ordinary ticks, minute-boundary misses, and longer
  stalls. The installed timer-driven fixture traversed warning, final
  countdown, breaking, and working successfully.
- The fixture now enters warning explicitly and disables synthetic natural
  pause, so it validates the real timer flow rather than depending on an
  unrelated detector state.
- Live diagnostics reported a 1,011 ms maximum scheduler gap and 1 ms maximum
  scheduler update duration, with no delayed-tick warning in the journal.

Quickshell cannot render frames while its UI thread or compositor is stalled.
The product guarantee is therefore correctness after a stall, not fabricated
intermediate frames: the next rendered value is current and never catches up
through obsolete seconds.

## Context

The installed service passed meeting, microphone, camera, screen-sharing,
video, generic media, fullscreen, and dictation fixtures through the real
scheduler. Every fixture produced protected context with the expected compact
label. Leaving demo mode restored the exact pre-test configuration.

Real-application verification remains a recurring release gate because
PipeWire roles, MPRIS metadata, hardware, and Wayland application identity are
supplied by other applications and can vary by system. Known platform limits
remain documented in [Detector Acceptance](detector-acceptance-2026-08-22.md)
and [Upstream Opportunities](upstream-opportunities.md).

## Repeat the check

```bash
./tests/check-live-reliability.sh
```

The script always leaves demo mode through a shell trap and verifies exact
configuration restoration before succeeding.

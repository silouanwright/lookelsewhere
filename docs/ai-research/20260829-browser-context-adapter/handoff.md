# Research Handoff: Browser Context Adapter

## Current conclusion

Build an optional Chromium-first precision adapter by extending the proven
Sundown event/native-messaging pattern with a minimal video-element content
script. Keep LookElsewhere's existing context engine authoritative and accept
only coarse booleans.

## Next step

Prototype in observe-only mode against Prime Video and YouTube. Print or expose
only the coarse browser context fixture, compare it with MPRIS/PipeWire evidence,
and do not integrate scheduling until foreground, muted, background, buffering,
and PiP transitions are correct.


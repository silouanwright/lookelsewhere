# ADR 0017: Bound and Shape Replaceable Data Before QML

- Status: Accepted
- Date: 2026-08-24

## Context

LookElsewhere runs inside the long-lived Omarchy Shell process. QML
`FileView.text()` and `StdioCollector` retain complete inputs before JavaScript
can validate them. The state file is user-replaceable, and active-window JSON
can contain application-controlled strings, so either source could otherwise
cause unbounded allocation in the shell.

## Decision

Apply byte limits at the producer boundary, before data enters QML. Read state
through the Qmlpack-managed `vendor/qmlpack/bounded-read/bin/bounded-read`
helper capped at 64 KiB and keep `FileView`
write-only. The helper opens with `O_NOFOLLOW | O_NONBLOCK`, verifies the open
descriptor is a regular file owned by the current user, and emits only the
bounded payload. Cap active-window output at 64 KiB and shape it outside QML
to one bounded application identifier and one fullscreen boolean.

Reject oversized, malformed, or stale input without partially applying it.
Preserve an unreadable state file and block further persistence until the user
resets or restores it.

## Consequences

The shell cannot be forced to retain arbitrarily large state or active-window
records through these paths. The implementation temporarily depends on standard
Omarchy command-line tools and an extra subprocess because Quickshell does not
provide byte-limited file or collector APIs.

This boundary is part of the privacy and reliability contract. Future inputs
that can be influenced outside the plugin must use the same producer-side cap
and shaping rule.

## Browser socket extension (2026-10-02)

Marketplace review #7717 found that the browser integration's receiving
`SocketServer` bypassed this rule: its default newline `SplitParser` could
buffer an unlimited unterminated frame, independently of the native host's
16 KiB limit. The regular-file `bounded-read` helper remains unchanged; a Unix
socket needs its own bounded receiver.

The browser receiver now runs outside Quickshell, with 4 KiB reads, 16 KiB
frames, eight clients, a two-second incomplete-frame deadline, and a
15-second idle timeout. Only normalized ASCII records of at most 1 KiB reach
QML, at most four times per second. QML consumes raw chunks with its own
bounded accumulator. The receiver has no detached descendants and is owned
by a Quickshell `Process`, including destruction on plugin unload.

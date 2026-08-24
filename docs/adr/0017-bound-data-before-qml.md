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
through a descriptor-bound helper capped at 64 KiB and keep `FileView`
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

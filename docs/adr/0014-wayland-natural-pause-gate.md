# ADR 0014: Gate Due Breaks on a Short Wayland Input Pause

- Status: Accepted
- Date: 2026-08-22

## Context

LookElsewhere promises to interrupt at a better moment, but protected-context
detection alone cannot distinguish the middle of an active typing burst from a
natural transition. The previous scheduler entered its warning immediately
when focus time became due unless a protected context or cooldown was active.
That contradicted the product language and made the central interaction less
considerate than intended.

## Decision

Use a second Quickshell `IdleMonitor` with a five-second timeout as a transient
input-quiet signal. This monitor ignores idle inhibitors because fullscreen,
media, microphone, and dictation policy are evaluated separately by Smart
Context. Once a break is due, the engine waits until this short monitor reports
quiet input, then begins the warning.

During the final ten seconds, a two-second monitor also holds the countdown at
ten seconds while keyboard or pointer activity continues. The bar reports this
privacy-preserving approximation as `Active`; after two quiet seconds the
countdown resumes. Wayland does not expose typed keys or pointer coordinates to
the plugin.

The recent-input window deliberately exceeds the one-second scheduler interval.
A one-second window can expire immediately before an observation, intermittently
missing sparse input depending on clock phase. `Service.typingQuietSeconds`
keeps that runtime calibration explicit: raise it only if real input is still
missed, and lower it only if quiet users are held too long. The visible policy
remains unchanged: activity holds the countdown at ten seconds.

The existing maximum smart-delay bound applies to this wait. Continuous input
therefore cannot suppress a break indefinitely. The ordinary 60-second idle
monitor remains responsible for excluding away time from focus accumulation.

## Consequences

- Warnings are more likely to arrive between actions instead of during them.
- No keystrokes, pointer coordinates, counts, or application content are read
  or persisted.
- The scheduler gains a distinct `naturalPause` observation input and exposes
  `naturalPauseReady` through status IPC for live acceptance testing.
- Five seconds is intentionally a product default, not an MVP setting. It can
  become configurable only if user evidence shows meaningful variation.

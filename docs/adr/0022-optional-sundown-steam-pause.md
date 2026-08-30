# ADR 0022: Use Optional Sundown Evidence to Pause During Steam Games

- Status: Accepted
- Date: 2026-08-29

## Context

Hyprland exposes the focused window class, so LookElsewhere can protect common
Steam windows such as `steam` and `steam_app_<id>`. That is not an authoritative
game signal: native games may use unrelated classes, the Steam client is not a
game, and process-level Proton identity is outside a shell plugin's normal
scope.

Sundown already distinguishes actual Steam and Proton game processes from the
client. Copying its `/proc` scanner into LookElsewhere would create two privacy
boundaries and two implementations of the same platform-specific logic.

## Decision

Keep Sundown optional. When its fresh version-1 public status is available,
consume only the Steam active boolean and bounded detector name. Pause interval
active-time accounting while a game is active, but continue treating the user
as present so gameplay cannot trigger LookElsewhere's away-session reset.

Watch Sundown's root-owned, atomically replaced `/run/sundown/status.json`
instead of polling its CLI. Reject unsupported or oversized status, expire the
signal after five seconds without an update, and fall back to focused-window
protection immediately.

The manifest-backed `pauseDuringSteamGames` setting controls this behavior and
defaults on. Without Sundown, LookElsewhere remains fully functional: matching
protected windows still delay due breaks, but they continue accumulating active
time under the existing protected-context policy.

## Alternatives

- Duplicate Sundown's process scanner: rejected because detection already has
  an authoritative owner and shell plugins should not independently inspect the
  process environment.
- Require Sundown: rejected because ordinary eye-break scheduling and window-
  based protection must remain self-contained.
- Run `sundown status --json` every second: rejected because the daemon already
  publishes atomic live state and recurring child processes add needless churn.
- Pause every protected application: rejected because “do not interrupt this
  context” and “do not count this activity” are separate policies.

## Consequences

The bar and panel expose `Game` while the timer is paused, and diagnostics name
the integration state, detector, raw game-active state, and effective pause.
Sundown upgrades accuracy without becoming a package dependency. Live release
verification still needs at least one real Steam or Proton game because process
metadata comes from third-party applications.

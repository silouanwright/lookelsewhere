# Research Handoff: Planned Breaks

## Goal

Define and implement native recurring planned breaks in LookElsewhere.

## Current conclusion

Use the existing explicit scheduler and persistence model. Calendar integration
is a later input adapter, not the scheduling foundation.

The behavior contract and ADR 0021 are accepted. Commit `decfef2` implements
the pure recurrence/configuration foundation: bounded routine normalization,
weekly overlap detection including midnight/week wrap, local occurrence keys,
late windows, handled-occurrence bounds, and cumulative away-time credit. The
suite currently passes 85 tests.

## Important source files

- `findings.md`
- `gaps.md`
- `source-ledger.md`
- `docs/research/archive/lookaway-public-audit.md`
- `docs/research/archive/state-machine.md`
- `Model.js`
- `Service.qml`

## Next steps

Integrate the active planned occurrence into `Model.observe`, completion,
postpone, skip, recovery, statistics, and `Service.qml`; then add deterministic
transition tests before building the settings editor or visual surfaces.

## Resume prompt

Read this handoff, ADR 0021, and the planned helper functions in `Model.js`.
Continue with scheduler integration. Do not re-open the calendar question or
redo the official LookAway audit unless a contradiction appears.

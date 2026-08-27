# Research Handoff: Planned Breaks

## Goal

Define and implement native recurring planned breaks in LookElsewhere.

## Current conclusion

Use the existing explicit scheduler and persistence model. Calendar integration
is a later input adapter, not the scheduling foundation.

The behavior contract and ADR 0021 are accepted. The native implementation is
complete: bounded recurrence, overlap detection, protected-context grace,
away-time credit, interval coalescing, restart recovery, planned outcomes,
deterministic demo fixtures, and a keyboard-accessible Plans editor. The suite
passes 91 tests.

## Important source files

- `findings.md`
- `gaps.md`
- `source-ledger.md`
- `docs/research/archive/lookaway-public-audit.md`
- `docs/research/archive/state-machine.md`
- `Model.js`
- `Service.qml`

## Next steps

Use the native scheduler in daily work and collect corrections. Calendar
integration remains a future input adapter and should not replace recurrence.

## Resume prompt

Read this handoff, ADR 0021, and the planned helper functions in `Model.js`.
Continue from the shipped native behavior. Do not re-open the calendar question
or redo the official LookAway audit unless a contradiction appears.

# Research Handoff: Planned Breaks

## Goal

Define and implement native recurring planned breaks in LookElsewhere.

## Current conclusion

Use the existing explicit scheduler and persistence model. Calendar integration
is a later input adapter, not the scheduling foundation.

## Important source files

- `findings.md`
- `gaps.md`
- `source-ledger.md`
- `docs/research/archive/lookaway-public-audit.md`
- `docs/research/archive/state-machine.md`
- `Model.js`
- `Service.qml`

## Next steps

Read the cited product research and scheduler implementation, settle the open
decisions, then write an ADR and deterministic acceptance cases before coding.

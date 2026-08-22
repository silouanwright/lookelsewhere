# ADR 0011: Make Every State Deterministically Stageable

- Status: Accepted
- Date: 2026-08-22

## Context

Waiting real intervals or requiring an actual meeting makes development, screenshots, tests, and judging unreliable and risks exposing private data.

## Decision

Provide guarded synthetic fixtures and IPC routes for every material state and transition. Demo mode runs quickly, does not inspect real context, and does not mutate normal persistent state.

## Alternatives

- Manual timing and live signals: rejected as nondeterministic.
- Hard-coded fake production UI: rejected because fixtures must exercise real surfaces and state mappings.

## Consequences

Fixture boundaries must be impossible to activate accidentally in ordinary use and must be documented for reviewers.

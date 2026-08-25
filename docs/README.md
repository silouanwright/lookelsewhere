# LookElsewhere Documentation

This directory preserves the product decisions, implementation contract,
research, and release evidence needed to continue the project without relying
on a particular workstation or chat history.

## Start here

- [Configuration reference](../CONFIGURATION.md)
- [Product brief](product-brief.md)
- [Architecture](architecture.md)
- [State model](state-model.md)
- [Experience and surfaces](experience.md)
- [Privacy and trust](privacy.md)
- [State I/O security review](state-io-security.md)
- [Verification strategy](verification.md)
- [Showcase renderer](showcase-renderer.md)
- [Upstream opportunities](upstream-opportunities.md)
- [Architecture decision records](adr/README.md)

The manifest is the machine-enforced configuration contract;
[`CONFIGURATION.md`](../CONFIGURATION.md) is its human-facing companion. The
architecture, state, experience, and privacy documents describe the current
implementation. ADRs explain why consequential choices were made.

## Planning and release records

- [Product priorities](product-priorities.md)
- [Competition MVP requirements](mvp-requirements.md)
- [Completion matrix](completion-matrix.md)
- [Design feedback reconciliation](design-feedback-reconciliation.md)
- [Marketplace submission record](marketplace-submission.md)
- [Submission checklist](submission-checklist.md)
- [QML review and remediations](qml-review-2026-08-22.md)
- [Runtime verification](runtime-verification-2026-08-22.md)
- [Live detector acceptance](detector-acceptance-2026-08-22.md)

These are dated snapshots. They preserve release evidence and earlier scope,
but they do not override the current implementation, manifest, configuration
reference, or accepted ADRs.

## Research archive

- [Research archive and synthesis](research/README.md)
- [Eye-health evidence and content guide](research/eye-health-evidence-and-content-guide.md)
- [Next-round product opportunities](research/next-round-opportunities.md)
- [GitPulse keyboard-first audit](research/gitpulse-keyboard-audit-2026-08-22.md)

## Documentation rules

- ADRs record consequential decisions, alternatives, and consequences.
- Current product documents describe accepted behavior; dated planning and
  release records preserve what was known at that point in time.
- Unproven technical assumptions are labeled as validation conditions.
- If implementation contradicts an accepted ADR, amend or supersede the ADR before treating the new behavior as intentional.
- Avoid medical claims. LookElsewhere supports healthier screen-break habits but does not diagnose, prevent, or treat disease.

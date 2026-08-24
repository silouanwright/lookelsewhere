# ADR 0019: Reviewable Source Packages

- Status: Accepted
- Date: 2026-08-24

## Context

LookElsewhere developed a reusable keyboard-first QML control library and a
descriptor-safe bounded file reader. Copying those files into another Omarchy
plugin would lose their origin, revision, update history, and review boundary.
Omarchy 4.x does not install plugin dependencies for users.

## Decision

Publish the reusable controls and bounded reader as independently released
packages in `silouanwright/omatools`. Manage them with Qmlpack and commit
`qmlpack.json`, `qmlpack.lock`, and `vendor/qmlpack` in LookElsewhere.

Developers review every prepared package and update before applying it. The
lock records exact GitHub repository identity, release tag, commit, file
digests, and package digest. Integrity verification does not certify source as
safe.

Keep product-specific surfaces and `PanelPattern` inside LookElsewhere. End
users continue installing one self-contained Omarchy plugin and do not need the
Qmlpack CLI.

## Consequences

The extracted source now has independent provenance and releases without
changing LookElsewhere's marketplace installation. If Omarchy later installs
declared plugin dependencies natively, Qmlpack can supply the same resolved
lock data without requiring committed vendor directories.

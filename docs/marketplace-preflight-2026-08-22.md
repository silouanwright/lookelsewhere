# Marketplace Preflight — 2026-08-22

This preflight used the current `main` branch of the official
`HANCORE-linux/omarchy-plugin-marketplace` repository at commit
`bf2ede0927040a96a6401a85d38770692cb0fd41`. It does not publish or submit
Look Elsewhere.

## Automated Security Baseline

The marketplace's dependency-free V3 analysis was run locally against the
same root README and runtime files its snapshot scanner selects, including all
three manifest entry points. The result was:

- outcome: `passed`
- enforcement mode: `selective`
- disposition: `clear`
- blocks approval: `false`
- findings: none
- review capabilities: none

This is a compatibility preflight, not a security audit. The official workflow
will repeat the static scan against the exact public GitHub commit.

## Submission contract

The issue body in [marketplace-submission.md](marketplace-submission.md) was
passed through the marketplace's current `parseCurrentSubmission` function
after changing only the intentionally deferred public-repository checkbox to
checked. The parser accepted:

- all six required headings in order;
- category `Productivity`;
- tags `bar`, `hyprland`, and `quickshell`; and
- all five official checklist statements verbatim and checked.

## Deferred public check

The marketplace's full `inspectSubmission` compatibility path requires a
public, active, unarchived GitHub repository and resolves an exact 40-character
commit through the GitHub API. That gate cannot truthfully run before Silouan
Wright authorizes publication. After publication, it must be run against the
public repository before the issue is submitted.

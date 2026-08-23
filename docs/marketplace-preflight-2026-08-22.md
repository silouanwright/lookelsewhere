# Marketplace Preflight — 2026-08-22

This preflight was rechecked against the current `main` branch of the official
`HANCORE-linux/omarchy-plugin-marketplace` repository at commit
`efa8117a78c21e9318079c5525a01525f5b21328`. The submission contract and
security-scanner sources are unchanged from the earlier reviewed revision. It
does not publish or submit Look Elsewhere.

## Automated Security Baseline

The marketplace's dependency-free V3 analysis was rerun locally against Look
Elsewhere's final runtime and README tree at commit
`cb32c9f17a7ec2351073cd702b680ff14fb2d51d`, using the same root README and 12
runtime files its snapshot scanner selects, including all three manifest entry
points. The result was:

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

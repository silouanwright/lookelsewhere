# Planned Breaks Source Ledger

## Scope Fence

Current lane: native planned-break scheduling for LookElsewhere.

Allowed roots:

- `/home/silouan/Repos/look-elsewhere`
- Official LookAway documentation and release notes already cited by the project
- Official Qt, Quickshell, Omarchy, Hyprland, and freedesktop documentation when needed

Forbidden roots:

- Unrelated repositories under `/home/silouan/Repos` or `/home/silouan/Work`
- Calendar-provider integration, which is explicitly deferred
- Broad Downloads or screenshot searches unless a specific missing artifact is identified

Out-of-scope fallback rule: if evidence is unavailable in the allowed roots or
official sources, record the gap rather than broadening the search silently.

| Source | Location | Tier | Relevance |
| --- | --- | --- | --- |
| LookAway public audit | `docs/research/archive/lookaway-public-audit.md` | 2 | Existing comprehensive product and edge-case audit |
| LookElsewhere state-machine draft | `docs/research/archive/state-machine.md` | 1 | Earlier scheduling invariants and collision policy |
| Next-round opportunities | `docs/research/next-round-opportunities.md` | 1 | Accepted product sequence and planned-break requirements |
| Current model and service | `Model.js`, `Service.qml` | 1 | Authoritative implementation boundary |
| LookAway Planned Breaks documentation | https://lookaway.com/docs/planned-breaks/ | 1 | Current documented configuration and runtime behavior |
| LookAway 2.2 release note | https://lookaway.com/blog/2026/06/22/lookaway-22-introducing-planned-breaks/ | 1 | Product rationale and examples |

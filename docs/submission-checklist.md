# Final Submission Checklist

Run this checklist against one exact commit. If the commit changes after any
release gate, repeat the affected checks before publication or marketplace
submission.

## Repository gate

- [x] `git status --short` is empty.
- [x] `manifest.json` identifies `io.github.silouanwright.look-elsewhere`,
  version `0.1.0`, author Silouan Wright, and MIT licensing.
- [x] The plugin ID is still absent from the public marketplace registry.
- [x] README installation and removal commands match the current Omarchy CLI.
- [x] `LICENSE` and `THIRD_PARTY_NOTICES.md` cover the shipped code and icons.
- [ ] Root `preview.png` and every README asset are original Look Elsewhere
  captures from the exact release UI. The current originals predate the final
  focused-application and panel refinements and must be recaptured.
- [x] No secrets, raw personal context, generated state, or machine-specific
  paths are tracked.

## Automated gate

- [x] `git diff --check` passes.
- [x] All Qt Quick model tests pass offscreen.
- [x] `omarchy plugin validate .` passes.
- [x] Deterministic lint and system `qmllint` findings are reviewed against the
  documented Omarchy import limitations.
- [x] The exact runtime source passes the focused QML semantic review.
- [x] The official marketplace V3 static analysis passes with no findings or
  review capabilities, and the drafted issue body passes the current official
  submission parser when its deferred public-repository checkbox is checked.

## Installed-runtime gate

- [x] Clean add, enable, disable, and remove paths work without an install hook,
  privilege escalation, orphaned process, or user-config overwrite.
- [x] Real scheduling survives shell restart with demo mode off.
- [x] Invalid persisted JSON is preserved, writes remain blocked, the recovery
  message is visible, and exact restoration resumes normal persistence.
- [x] Idle state visibly pauses the bar and panel countdown.
- [x] Warning begins before focus reaches zero, final countdown follows, and
  the break starts at the original zero without a second warning cycle.
- [x] Casual and Balanced exits work while Hardcore rejects button, Escape,
  modified-Escape, and IPC skips until natural completion.
- [x] Keyboard traversal, Escape dismissal, accessible roles/names, and reduced
  motion are verified.
- [x] Dark and light themes, supported bar edges, scaled/narrow layouts, shell
  reload, and available multi-monitor behavior are recorded honestly.
- [x] The final run leaves the real schedule restored and produces no new shell
  QML errors or coredumps.

## Public-release gate

- [ ] Silouan approves the exact commit SHA, public repository creation/push,
  README copy, preview rights, and all five marketplace checklist statements.
- [ ] Silouan confirms he can receive a prize by Zelle, Venmo, PayPal, or EU
  IBAN, as required by the competition rules.
- [ ] The GitHub repository is public at
  `https://github.com/silouanwright/look-elsewhere` and its default branch HEAD
  equals the approved SHA.
- [ ] Installation from the public URL succeeds on the installed Omarchy
  release and the public clone validates.
- [ ] The marketplace issue preserves all six required headings in order,
  uses category `Productivity`, uses one to three allowed tags, and contains
  the five official checklist statements verbatim and checked.
- [ ] The completed issue title and body are shown to Silouan and receive a
  final explicit approval before `gh issue create` runs.
- [ ] The submission is created before Monday, 2026-08-24 at 09:00 CEST and
  automated compatibility/security results are monitored on the existing issue.

Official references:

- [Competition announcement](https://omarchy.org/news/2026/08/the-first-plugin-competition/)
- [Marketplace submission contract](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md)
- [Marketplace publishing guide](https://omarchyplugins.com/publish.html)

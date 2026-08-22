# Final Submission Checklist

Run this checklist against one exact commit. If the commit changes after any
release gate, repeat the affected checks before publication or marketplace
submission.

## Repository gate

- [ ] `git status --short` is empty.
- [ ] `manifest.json` identifies `io.github.silouanwright.look-elsewhere`,
  version `0.1.0`, author Silouan Wright, and MIT licensing.
- [ ] The plugin ID is still absent from the public marketplace registry.
- [ ] README installation and removal commands match the current Omarchy CLI.
- [ ] `LICENSE` and `THIRD_PARTY_NOTICES.md` cover the shipped code and icons.
- [ ] Root `preview.png` and every README asset are original Look Elsewhere
  captures from the exact release UI.
- [ ] No secrets, raw personal context, generated state, or machine-specific
  paths are tracked.

## Automated gate

- [ ] `git diff --check` passes.
- [ ] All Qt Quick model tests pass offscreen.
- [ ] `omarchy plugin validate .` passes.
- [ ] Deterministic lint and system `qmllint` findings are reviewed against the
  documented Omarchy import limitations.
- [ ] The exact commit passes the focused QML semantic review.

## Installed-runtime gate

- [ ] Clean add, enable, disable, and remove paths work without an install hook,
  privilege escalation, orphaned process, or user-config overwrite.
- [ ] Real scheduling survives shell restart with demo mode off.
- [ ] Invalid persisted JSON is preserved, writes remain blocked, the recovery
  message is visible, and exact restoration resumes normal persistence.
- [ ] Idle state visibly pauses the bar and panel countdown.
- [ ] Warning begins before focus reaches zero, final countdown follows, and
  the break starts at the original zero without a second warning cycle.
- [ ] Gentle, Balanced, and Focused exits match their documented policy;
  `Ctrl+Shift+Esc` remains available in Focused mode.
- [ ] Keyboard traversal, Escape dismissal, accessible roles/names, and reduced
  motion are verified.
- [ ] Dark and light themes, supported bar edges, scaled/narrow layouts, shell
  reload, and available multi-monitor behavior are recorded honestly.
- [ ] The final run leaves the real schedule restored and produces no new shell
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

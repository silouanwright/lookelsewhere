# Marketplace Submission Draft

This draft follows the community marketplace submission contract verified on
2026-08-23. Do not create the external issue until Silouan Wright has reviewed
the exact validated commit, preview rights, and all five checklist statements.

## Proposed listing

- Title: `[Plugin]: LookElsewhere`
- Category: `Productivity`
- Tags: `bar`, `hyprland`, `quickshell`
- Suggested missing tag: `wellbeing`

## Issue body

```markdown
### Repository URL

https://github.com/silouanwright/lookelsewhere

### Category

Productivity

### Tags

bar, hyprland, quickshell

### Suggest a missing tag

wellbeing

### Maintainer notes

LookElsewhere is a local-first active-use break coach. It uses coarse Omarchy
and Wayland context signals to avoid interrupting meetings, media, fullscreen
work, and dictation. It does not capture screen content, record audio, retain
window or media titles, create accounts, or use the network.

It has no installer or background service and never calls `sudo` or `pkexec`.
Outside its own plugin directory, it writes only private scheduler state to
`~/.local/state/look-elsewhere/state.json`; configuration is managed by
Omarchy in `shell.json`. It invokes `hyprctl` for active-window fallback,
`omarchy-voxtype-status` for optional dictation state, and
`canberra-gtk-play` for break cues. Missing optional integrations degrade
gracefully. Bundled sounds can be disabled or replaced with user-provided
files.

Removal is
`omarchy plugin remove io.github.silouanwright.look-elsewhere`.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
```

## Submission command

After explicit approval:

```bash
gh issue create \
  --repo HANCORE-linux/omarchy-plugin-marketplace \
  --title "[Plugin]: LookElsewhere" \
  --body-file /tmp/omarchy-plugin-submission.md
```

Authoritative references:

- <https://github.com/basecamp/omarchy/blob/quattro/manual/32-shell-plugins.md>
- <https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md>

All five statements describe the prepared repository. The completed title and
body still require the owner's explicit approval before submission.

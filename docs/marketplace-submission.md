# Marketplace Submission Draft

This draft follows the community marketplace submission contract verified on
2026-08-22. Do not create the external issue until the repository is public and
Silouan Wright has reviewed the exact validated commit, preview rights, and all
five checklist statements.

## Proposed listing

- Title: `[Plugin]: Look Elsewhere`
- Category: `Productivity`
- Tags: `bar`, `hyprland`, `quickshell`
- Suggested missing tag: `wellbeing`

## Issue body

```markdown
### Repository URL

https://github.com/silouanwright/look-elsewhere

### Category

Productivity

### Tags

bar, hyprland, quickshell

### Suggest a missing tag

wellbeing

### Maintainer notes

Look Elsewhere is a local-first active-use break coach. It uses coarse Omarchy
and Wayland context signals to avoid interrupting meetings, media, fullscreen
work, and dictation. It does not capture screen content, record audio, retain
window or media titles, create accounts, or use the network.

### Submission checklist

- [ ] The repository is public. Publication remains intentionally pending final approval; installation and removal instructions are ready.
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
  --title "[Plugin]: Look Elsewhere" \
  --body-file /tmp/omarchy-plugin-submission.md
```

Authoritative references:

- <https://github.com/basecamp/omarchy/blob/quattro/manual/32-shell-plugins.md>
- <https://github.com/HANCORE-linux/omarchy-plugin-marketplace/blob/main/SUBMISSION.md>

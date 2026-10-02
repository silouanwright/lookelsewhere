# Marketplace Submission Record

LookElsewhere is listed in the community Omarchy plugin marketplace.

- Plugin ID: `io.github.silouanwright.look-elsewhere`
- Repository: <https://github.com/silouanwright/lookelsewhere>
- Category: `Productivity`; tags: `bar`, `hyprland`, `quickshell`
- Initial listing: [issue #1785](https://github.com/omacom/omarchy-plugin-marketplace/issues/1785)
  (submitted 2026-08-23, listed 2026-08-24, closed 2026-08-24)
- First verified snapshot: `1225de0632e6dff2874deeb3f4896fe026bdd8e4`
  ("Polish keyboard hint placement", validated 2026-08-25)
- Current update request: [issue #7717](https://github.com/omacom/omarchy-plugin-marketplace/issues/7717),
  opened for 0.3.0 on 2026-09-19. Version 0.3.1 fixes the receiving-socket
  byte-limit finding from 2026-09-30 and is submitted through the same issue.
  Marketplace promotion remains subject to exact-commit validation and maintainer approval.

## Publishing a new version

The marketplace repository moved from `HANCORE-linux/omarchy-plugin-marketplace`
to `omacom/omarchy-plugin-marketplace` (old links redirect), and version updates
no longer use the `[Plugin]:` submission form. A released version is promoted
through the **Plugin verification** issue form:

<https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=verify-plugin.yml>

1. Select **Verify and publish a newer upstream commit**.
2. Enter the existing plugin ID, the repository root URL, and the full
   40-character commit SHA of the release commit.
3. The requested SHA must be the repository's default-branch HEAD when the
   issue is validated (`update-upstream-changed` otherwise), and the configured
   plugin ID set must not change (`update-plugin-set-changed`).
4. Automated compatibility validation and the Automated Security Baseline run
   against that exact commit. A write-authorized maintainer then applies
   `approved-and-verified`; publication is atomic and the superseded snapshot is
   retained in the registry's `listingValidationHistory`.
5. Do not push to `main` between opening the issue and promotion, or the
   requested commit stops matching the observed upstream HEAD.

The version shown on the marketplace card comes from `manifest.json` at the
submitted commit, so bump it before releasing.

Site (canonical): <https://plugins.omarchy.org> — `omarchyplugins.com` redirects
there, and `plugins.omarchy.com` does not exist.

## Issue body contract

The issue title must start with `[Verify]:`. The body must contain exactly these
six `###` headings, in this order, with no additional headings:

```markdown
### Verification action

Verify and publish a newer upstream commit

### Plugin ID

io.github.silouanwright.look-elsewhere

### Repository URL

https://github.com/silouanwright/lookelsewhere

### Target commit

<full 40-character SHA of the release commit>

### Verification acknowledgment

- [x] I understand that only the exact target commit can become a verified marketplace snapshot and that verification is not a security audit.

### Standard installation acknowledgment

_No response_
```

The install path stays the standard mutable-upstream command published on the
listing (`omarchy plugin add https://github.com/silouanwright/lookelsewhere.git
--enable`), so no manual-installation override applies and the standard
installation acknowledgment stays unselected.

Authoritative references:

- <https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md>
- <https://github.com/omacom/omarchy-plugin-marketplace/blob/main/VERIFICATION.md>
- <https://github.com/basecamp/omarchy/blob/quattro/manual/32-shell-plugins.md>
- <https://plugins.omarchy.org/publish.html>

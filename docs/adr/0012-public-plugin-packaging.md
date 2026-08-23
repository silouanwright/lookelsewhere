# ADR 0012: Package as a Public Dependency-Light Marketplace Plugin

- Status: Accepted
- Date: 2026-08-22

## Context

The competition and marketplace expect a public GitHub repository, root manifest, safe installation/removal, documentation, license, and optional preview. Plugins run unsandboxed with user permissions.

## Decision

Publish `silouanwright/lookelsewhere` under MIT with root plugin files, documented commands, no install hook, no privilege escalation, no required network service, and the fewest practical dependencies.

## Alternatives

- Installer script and system service: rejected for contest trust and friction.
- Private or monorepo-only distribution: rejected as ineligible/unfriendly.

## Consequences

The repository itself must be the installable plugin root. Preview/demo assets and README quality are part of the product, and external submission must reference the verified commit.

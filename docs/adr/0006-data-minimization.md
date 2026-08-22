# ADR 0006: Minimize and Localize Observed Data

- Status: Accepted
- Date: 2026-08-22

## Context

Context-aware timing could easily become activity surveillance. The feature does not require content history or remote analytics.

## Decision

Observe only transient local state needed for category inference. Never persist or display titles, URLs, meeting names, transcripts, audio, video, screenshots, clipboard data, or application timelines. Provide detector toggles and local-data reset.

## Alternatives

- Detailed activity history: rejected as unnecessary and privacy-invasive.
- Cloud analytics: rejected.
- Content-based detection: deferred/rejected for MVP.

## Consequences

Diagnostics must be useful without raw metadata. Demo fixtures use synthetic data exclusively.

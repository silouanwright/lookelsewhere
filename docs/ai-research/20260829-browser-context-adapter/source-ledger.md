# Source Ledger: Browser Context Adapter

## Scope fence

- Current lane: whether Sundown's Chromium extension architecture can improve
  LookElsewhere browser-video context.
- Allowed roots: `/home/silouan/Work/sundown`, the Sundown Codex thread
  `01a04718-3399-7053-83ce-ef1d88c7f335`, this LookElsewhere repository, and
  official browser/Web API documentation.
- Forbidden roots: unrelated Codex threads and unrelated browser extensions.

| Source | Tier | Relevance |
|---|---:|---|
| Sundown conversation and `browser-extension/chromium/service-worker.js` | 1 | Proven local native-messaging, focused-tab, idle, audible-tab, heartbeat, and privacy boundaries |
| [Chrome Tabs API](https://developer.chrome.com/docs/extensions/reference/api/tabs) | 1 | `active`, window focus distinction, `audible`, and muted state |
| [Chrome content scripts](https://developer.chrome.com/docs/extensions/develop/concepts/content-scripts) | 1 | Page DOM inspection and isolated-world boundary |
| [Chrome native messaging](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging) | 1 | Extension-to-local-process transport and origin allowlisting |
| [HTMLMediaElement](https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement) | 1 | Direct video element playback/readiness/events |
| [Page Visibility](https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilityState) | 1 | Foreground/hidden document state |
| [Picture-in-Picture](https://developer.mozilla.org/en-US/docs/Web/API/Document/pictureInPictureElement) | 1 | Direct PiP state, with iframe/browser compatibility limitations |


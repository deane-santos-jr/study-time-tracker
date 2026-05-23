---
status: accepted
---

# Single `POST /sync` batch endpoint for mobile sync

The mobile client maintains a local **Sync Queue** of pending mutations while offline (ADR-0002). To drain that queue, the backend exposes a single `POST /sync` endpoint that accepts a batch envelope of pending events plus a `lastServerCursor`, processes them atomically, and returns the new cursor plus any server-side changes the client should pull. The legacy per-action endpoints (`/sessions/start`, `/pause`, `/resume`, `/end`, `/breaks/...`) stay in place for the frozen web app but are not called by the mobile client.

A single round trip drains an arbitrary number of queued events in one TCP/TLS handshake, which dominates the per-action option on cellular networks and on battery. The frozen web app continues to use per-action endpoints since it is online-only.

## Considered Options

- **Per-action endpoints with idempotency keys (option A)** — rejected: simpler but multiplies round trips and radio wakes during sync drains; chosen explicitly against for performance reasons.
- **Single `POST /sync` envelope (option B)** — chosen.
- **Event-sourced API as the backend write model (option C)** — rejected: same sync perf as B but turns the backend into an event store, weeks of unrelated rewrite for no marginal perf gain.

## Consequences

- Envelope versioning becomes the backend's evolution surface. The envelope carries a `schemaVersion` so the server can reject envelopes it doesn't understand and the client can refuse to drain a queue it can't safely serialize.
- Atomic batch semantics: an envelope either fully applies or fully fails. A single bad event aborts the batch; the client receives a per-event error map and decides whether to drop the bad event or retry. This must be carefully designed so a poison-pill event can't permanently block sync.
- Two API surfaces now exist with overlapping write semantics. Documented clearly: the web app uses per-action; the mobile app uses `/sync`. Future deletion of per-action endpoints depends on whether the web app survives long term.
- The backend needs a `device_id` check inside `/sync` to enforce the **Authoritative Device** rule from ADR-0002.

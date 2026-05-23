---
status: accepted
---

# Offline-first mobile client with single-device authority per account

Study sessions happen exactly where networks are flaky: libraries, classrooms, buses. An online-only mobile client would refuse to start a timer in a basement — unacceptable. We make the phone authoritative for the **Active Session**: writes go to local SQLite first, then to the **Sync Queue** for eventual replay against the backend. The backend stays the long-term source of truth for history and cross-device reads.

To avoid the complexity of true multi-device sync (CRDTs, vector clocks, conflict merge rules), only one device per account is treated as the **Authoritative Device** at a time. Logging in on a new device force-logs-out the previous one on next contact, and the old device's unsynced **Sync Queue** entries are abandoned.

## Considered Options

- **Online-only** — rejected: timer refuses to operate without signal.
- **Online with local action buffer** — rejected: simpler, but still treats network as required for the happy path. The buffer would have to grow into a real sync engine the moment a real-world dropout lasted more than a few minutes.
- **Offline-first, multi-device** — rejected: real sync conflict resolution is multi-week work for an issue ~0 of our users will hit.
- **Offline-first, single-device** — chosen.

## Consequences

- Backend needs idempotency on session-mutation endpoints (client UUID as the key) so retries from the queue are safe.
- Backend tracks `current_device_id` per user; writes from a stale device are rejected at sync time.
- The frozen web app is read-only for **Study Sessions** while a mobile device is the **Authoritative Device**.
- Multi-device sync becomes a future migration if user demand appears; deliberately deferred.
- A device that has lost authority (e.g. user re-logged-in on a new phone) and later comes back online gets a `409 NOT_AUTHORITATIVE` from `/sync`. The mobile app then locks into a recovery screen offering "Re-activate this device" (wipes local DB on the way) or "Export queued sessions" (share-sheet a JSON dump of unsynced rows). The server never accepts writes from a non-authoritative device — that path was explicitly rejected to avoid sliding into multi-device merge logic.

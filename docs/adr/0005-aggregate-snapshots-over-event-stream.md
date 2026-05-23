# Aggregate snapshots in the `/sync` envelope, not event streams

Inside the `POST /sync` envelope (ADR-0004), each pending **Study Session** is sent as a full aggregate (start/end timestamps, status, child **Breaks**) rather than as a stream of domain events. The backend upserts the aggregate against the existing `study_sessions` and `breaks` tables. Event sourcing was rejected because the single-device authoritative model (ADR-0002) removes the concurrent-mutator problem that justifies event logs, and the wall-clock timer (ADR-0003) means every aggregate is fully described by its timestamps alone.

## Consequences

- The existing `study_sessions` and `breaks` schema is reused without an additional event-log table.
- Schema evolution is additive — new fields on the aggregate don't require versioning per event type.
- A `clientUuid` on each aggregate provides idempotent upserts; replays from a flaky network are safe.

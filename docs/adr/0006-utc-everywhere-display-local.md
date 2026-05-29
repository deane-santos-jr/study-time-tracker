# UTC everywhere on the wire and at rest, device-local for display

All timestamps on the API and in the database are UTC. Mobile and the (frozen) web client convert to device-local for display only. The existing `DATETIME` columns in `study_sessions` and `breaks` are interpreted as UTC by convention; a future migration to `DATETIME(3)` adds millisecond precision without changing the zone contract. API payloads use ISO-8601 with the `Z` suffix; offsets and naïve local strings are rejected at the boundary.

This avoids the cross-zone session bug (student studying on a flight from Manila to Tokyo) and the daylight-saving footgun, at the cost of having to compute local-hour analytics from a device-supplied offset if and when that feature exists.

## Considered Options

- **UTC at rest, device-local for display** — chosen.
- **Store with explicit offset per session** — rejected: extra column for an analytics dimension no current feature uses.
- **Per-user fixed timezone preference** — rejected: incompatible with travel; produces silently wrong stats when a user crosses zones.

## Consequences

- Mobile clock skew is detected by comparing the server's UTC (returned on every sync) with the device clock; >2 min drift triggers a soft in-app warning but does not block use.
- Local-hour analytics ("you study most at 9pm") are not free; if shipped later, sessions will carry an optional `deviceOffsetMinutes` field. Cheap additive change to the aggregate envelope (ADR-0005).
- The **Wall-clock Timer** (ADR-0003) is unaffected by mid-session zone changes because elapsed is `now_utc - startTime_utc`.
- ADR-0015 adds a `users.timezone` (IANA) column for gamification local-day bucketing (**Daily XP Cap**, `STREAK_DAY_CONTINUED`). This does **not** reopen the rejected "per-user fixed timezone preference" option above: timestamps stay UTC at rest and on the wire, and it is never used to convert session times for display — only to decide which local calendar day a UTC-stamped event falls in. The travel footgun the rejection guarded against does not apply, since the worst case is an edge-of-midnight grant counted against the adjacent day.

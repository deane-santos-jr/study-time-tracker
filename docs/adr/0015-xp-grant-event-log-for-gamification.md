---
status: proposed
---

# XP grant event log for gamification

v2.0 introduces XP and Levels (`Lifetime` and `Semester` scopes, shared level curve, named `Tier` bands). XP is stored as an append-only `xp_grants` event log — each grant captures `amount`, `source`, `sourceRefId`, `semesterId`, and `awardedAt` at the moment of award. Current totals are always derived: `currentXp = SUM(amount)` (with `WHERE semesterId = ?` for the semester counter). The server runs the rules engine and is authoritative; the mobile client computes speculatively for instant level-up UX and reconciles on next sync.

This is a deliberate exception to ADR-0005's "aggregate snapshots over event streams" — ADR-0005 governs the **sync envelope shape** (and continues to). XP state lives in storage that is event-shaped because rule rebalancing must not retroactively rewrite a user's history.

## Considered Options

- **Pure derived (no XP state)** — rejected: every grant-rule rebalance (e.g. raising `HIGH_FOCUS_BONUS` from +30 to +50) retroactively rewrites every user's lifetime XP and level. Defensible only with explicit rule versioning, which is more machinery than the event log it tries to avoid.
- **Cached counter (`user_progression { currentXp, currentLevel }`)** — rejected: same rule-rebalancing problem as derived, plus cache-invalidation logic to maintain. Speed of read is a non-problem at our scale.
- **Hybrid: counter + grant log** — rejected: two sources of truth that must agree, with sync overhead and no benefit over just deriving from the log on read.
- **Append-only `xp_grants` event log** — chosen. Each grant is immutable; rule rebalancing changes future grant amounts but never touches historical rows. The grant log is auditable ("why am I level 17?" → show grants). Future leaderboards / anti-cheat work has a single canonical artifact to validate against.

## Consequences

- New entity `XpGrant` + new table `xp_grants` (columns: `id, user_id, semester_id, source, source_ref_id, amount, awarded_at, client_uuid`). Indexes on `(user_id, semester_id)` and `(user_id, awarded_at)`. Unique on `(user_id, client_uuid)` for sync idempotency reusing the ADR-0004 mechanism.
- New domain `XpSource` enum: `SESSION_COMPLETED`, `HIGH_FOCUS_BONUS`, `SCORE_LOGGED`, `SCORE_IMPROVED`, `PR_BROKEN`, `STREAK_DAY_CONTINUED`, `REVERSAL`. New sources are additive — they can be introduced in later releases without migrating historical rows.
- **Reversal grants** replace row mutation: when a source event (a deleted **Study Session**, an edited **Score**) invalidates an existing grant, the server appends a `REVERSAL` grant with `amount = −original` and `sourceRefId = <original grant id>`. The log stays append-only; current XP stays correct via `SUM`.
- **Dual scopes from one table.** `Lifetime XP = SUM(amount) WHERE user_id = ?`. `Semester XP = SUM(amount) WHERE user_id = ? AND semester_id = ?`. Both `Lifetime Level` and `Semester Level` derive from the same level curve. No second table, no second counter.
- **Server-authoritative rules engine** lives in `application/services/XpRulesEngine.ts` (TS). The mobile client (`mobile/lib/.../xp_rules_engine.dart`) re-implements the rules for speculative grants and reconciles when the server's authoritative grant lands in the next `/sync` response. Both implementations must stay in sync — they are pinned by a shared, language-neutral test corpus at the repo root, `xp-rules-corpus/`: JSON fixtures of `{ input event(s), expected grants }`, consumed by the backend Jest suite and the Flutter `flutter test` suite alike. The corpus is the contract; either engine failing a fixture is a build failure. New grant rules add fixtures here before they are implemented in either language.
- **`/sync` response gains an `xpGrants: [...]` block** carrying grants newly issued by the server in response to events in this envelope. No new endpoint needed for the core flow. Read endpoint: `GET /me/progression` returns `{ lifetimeXp, lifetimeLevel, lifetimeTier, semesters: [{ semesterId, semesterXp, semesterLevel, semesterTier }] }`. Optional `GET /me/xp-grants?cursor=...` for the in-app audit view.
- **Daily cap** is enforced inside the rules engine for `SESSION_COMPLETED` only — bonus sources stay uncapped. Enforcement queries `SUM(amount) WHERE user_id = ? AND source = 'SESSION_COMPLETED' AND awarded_at >= <user_local_midnight>`. This makes user timezone load-bearing.
- **`users` table gains a `timezone` column** (IANA, e.g. `Asia/Manila`) — required by the daily cap and by `STREAK_DAY_CONTINUED` for local-day boundaries. Default `UTC` on existing rows; mobile sets it on first launch from device locale.
- **`Tier` is a server-side constants table in code** (not a DB row): `BRONZE` (1–10), `SILVER` (11–25), `GOLD` (26–50), `PLATINUM` (51+). Boundaries are tunable via deploy; historical grants are unaffected since tier is derived from level, which is derived from the log.
- **One-shot backfill migration at launch** replays every completed historical **Study Session** through the rules engine, generating `SESSION_COMPLETED`, `HIGH_FOCUS_BONUS` (where a **Note** with `focusLevel ≥ 4` exists), `STREAK_DAY_CONTINUED` (per local-day chain), and seeds `PR_BROKEN` grants from existing ADR-0012 personal records. Migration is idempotent (keyed on `client_uuid` derived deterministically from `(source, source_ref_id)`). Score-related grants do not backfill — scores are a forthcoming feature.
- **ADR-0012 (Personal Records) is unaffected.** PRs remain client-detected, server-backstopped. The `PR_BROKEN` XP source is the only new coupling: server-side rules engine listens for PR row mutations and emits the grant.
- **Schema evolution.** New `XpSource` values require an enum migration but no data migration. The `amount` column is a signed INT so reversals do not need a separate field. Grant-amount tuning happens in code; the log absorbs whatever the rules engine emits on the day.

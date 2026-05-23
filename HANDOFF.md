# Handoff

## Goal

Turn the existing Study Time Tracker (React 19 + MUI web app talking to an Express + TypeORM + MySQL backend) into a native mobile app available on the iOS App Store and Google Play Store. This handoff covers the **design phase only** — no mobile code has been written yet. The next agent picks up with scaffolding and implementation.

The mobile rewrite is driven by:
- Students study where networks are flaky (libraries, classrooms, buses) — the web app's online-only behaviour is unacceptable on mobile.
- Planned social features (study with friends, leaderboards) need a real mobile presence and push notification infrastructure.

## Current Progress

A grill-with-docs design session on 2026-05-23 produced a complete architectural plan for the mobile rewrite. All decisions are captured as ADRs; current-state language lives in `CONTEXT.md`; the original `ARCHITECTURE.md` was updated rather than archived.

### Locked decisions (with ADR pointers)

1. **Flutter** for the mobile app (ADR-0001). Capacitor was the conservative recommendation; user chose Flutter despite the full Dart rewrite.
2. **React web app is frozen** as of 2026-05-23. Critical bug fixes only.
3. **Offline-first** with **single-device authority** per account (ADR-0002). New-device login force-logs-out the old device. Orphaned-device queue: `409 NOT_AUTHORITATIVE` from `/sync`, mobile shows a recovery screen with "Re-activate" or "Export queued sessions" buttons.
4. **Wall-clock timer** model — elapsed is derived from timestamps on every render, never persisted as a counter. Android foreground service + iOS local notification for the persistent "Studying: …" UX (ADR-0003).
5. **Single `POST /sync` batch endpoint** with `clientUuid` idempotency + `device_id` authoritative-device check (ADR-0004). Performance was the user's stated priority; batch wins on cellular round-trip count.
6. **Aggregate snapshots** in the sync envelope, not event streams (ADR-0005). Note rides embedded with its parent Session.
7. **UTC everywhere** on the wire and at rest, device-local for display (ADR-0006). Existing `DATETIME` columns are interpreted as UTC by convention.
8. **Server-driven push (FCM + APNs) + local notifications** (ADR-0007). Justified by the planned social roadmap.
9. **Client-side PDF export** via `pdf` + `printing` packages (ADR-0008). No backend `/export/*` endpoints. Original ARCHITECTURE.md plan rejected.
10. **Sync triggers**: on-action (debounced 500 ms), on-reconnect, on-foreground/cold launch. No periodic background sync.
11. **Auth on mobile**: `flutter_secure_storage` for refresh token, in-memory access token, silent sliding refresh (15-min access / 30-day sliding refresh), no app-level biometric gate.
12. **Repo structure**: monorepo — `mobile/` subdir alongside existing `backend/` and `frontend/`.
13. **Analytics computed on the phone** from local SQLite (consistent with offline-first + client-side PDF). The existing `/analytics/*` endpoints stay in place for the frozen web app.
14. **Implementation-detail picks** (not ADR'd because reversible):
    - Local DB: **Drift** (type-safe SQL over SQLite)
    - State management: **Riverpod**
    - Charts: **fl_chart**
    - HTTP: **dio** (interceptors for auth + sync-queue draining)
    - Android foreground service: **flutter_foreground_task**
    - Local notifications: **flutter_local_notifications**
    - Push: **firebase_messaging**
    - Connectivity: **connectivity_plus**
    - IDs: `uuid` package, v4 client UUIDs as idempotency keys

### Files written this session

- `CONTEXT.md` (new) — glossary covering Study Session, Active Session, Break, Subject, Semester, Note, Authoritative Device, Wall-clock Timer, Sync Queue; relationships; flagged ambiguity (Session vs JWT session).
- `ARCHITECTURE.md` (updated) — banner pointing to CONTEXT.md + ADRs, `Note` added to entities, new tables (`notes`, `processed_actions`, `device_push_tokens`, `users.current_device_id`), `/sync` + `/devices/*` + `/notes` endpoint blocks, `/export/*` block marked removed, new "Mobile Application" section, frontend marked frozen, Phases 7-10 added, roadmap refreshed.
- `docs/adr/0001-flutter-for-mobile.md` through `docs/adr/0008-client-side-pdf-export.md`.
- Memory entry `project_social-features-planned.md` plus `MEMORY.md` index entry — flags that single-device assumptions in ADR-0002 will be re-pressured when social features ship.

### Drift caught during the session

- `ARCHITECTURE.md` did not mention `notes`, but the backend has a full `notes` table + `NoteController` + `note.routes.ts`. Fixed during the update.
- `ARCHITECTURE.md` listed `/export/*` PDF endpoints as planned; no implementation exists. Decided not to implement them server-side and updated the doc accordingly.

## What Worked

- **Grill-one-question-at-a-time** kept the design tree explorable without it collapsing into a single all-or-nothing spec. Each fork was resolved with explicit alternatives + a recommendation + the reasoning, then locked into an ADR within the same turn.
- **Writing ADRs inline** (not batched at the end) meant the document set reflected the conversation in real time. Pre-checking the skill's `ADR-FORMAT.md` and `CONTEXT-FORMAT.md` before writing avoided format drift.
- **Pushing back on fuzzy language** (e.g. "performance above all else" in Q8) before answering surfaced what the user actually wanted to optimize. The user picked the batch sync endpoint informed by the trade-off table rather than the keyword.
- **Cross-referencing code while grilling** (the `notes` table drift, the existing `DATETIME` columns for UTC-on-the-wire discussion) caught real codebase facts that would have been wrong if assumed.

## Next Steps

Picking up from this design plan, in order:

1. **Scaffold `mobile/`** as a Flutter project alongside `backend/` and `frontend/`. Add it to root README / CLAUDE.md as the third subproject. `flutter create mobile --org com.studytimetracker` (adjust org as needed).
2. **Backend migrations.** Generate TypeORM migrations in `backend/src/infrastructure/database/migrations/`:
   - Add `current_device_id VARCHAR(36)` to `users`.
   - Create `processed_actions (user_id, client_uuid, action, processed_at)` with `PRIMARY KEY (user_id, client_uuid)`.
   - Create `device_push_tokens (user_id, device_id, platform, token, last_seen_at)` with `PRIMARY KEY (user_id, device_id)`.
   - Schema for these is in `ARCHITECTURE.md` "Database Schema" section.
3. **Implement `POST /sync/handshake`** — returns `{ currentDeviceId, lastServerCursor }`. New controller in `backend/src/presentation/controllers/` and route file in `backend/src/presentation/routes/sync.routes.ts`. Mount under `/api/v1/sync` in `index.ts`.
4. **Implement `POST /sync`** — accepts the aggregate envelope from ADR-0005. Apply each aggregate via `INSERT … ON DUPLICATE KEY UPDATE` keyed on `clientUuid`. Enforce `device_id` matches `users.current_device_id`; return `409 NOT_AUTHORITATIVE` otherwise. Insert into `processed_actions` to dedup retries.
5. **Implement device push token endpoints** (`POST /devices/register-push-token`, `DELETE /devices/push-token`) — wire to `device_push_tokens`. Gate behind `authenticate` middleware.
6. **Mobile auth flow.** Set up dio in `mobile/lib/` with an interceptor that:
   - Reads refresh token from `flutter_secure_storage`.
   - Refreshes silently on 401 via the existing `POST /auth/refresh`.
   - Includes `device_id` header on every request (UUID generated at first launch, stored in secure storage).
7. **Drift schema in `mobile/lib/db/`** mirroring backend tables for `subjects`, `semesters`, `study_sessions`, `breaks`, `notes`, plus a local `sync_queue` table.
8. **Wall-clock timer + foreground service.** Active session row in Drift, derived elapsed in UI, `flutter_foreground_task` integration on Android, `flutter_local_notifications` "Session in progress" on iOS.
9. **Sync engine.** Three triggers (action-debounced-500ms, on-reconnect via connectivity_plus, on-foreground/cold-launch). Build aggregate envelope from `sync_queue` + recently-changed rows; POST `/sync`; apply server response (new cursor, server-side changes).
10. **Implement the 409 recovery screen** in the mobile app — "Re-activate this device" (re-login flow, wipes local DB) or "Export queued sessions" (share-sheet JSON dump).
11. **Subjects / Semesters / Sessions / Breaks / Notes CRUD screens** — all backed by local Drift, sync via the engine. UI conventions can borrow from the frozen `frontend/` for parity.
12. **fl_chart analytics screens** computing all metrics on-device from local sessions.
13. **PDF export** via `pdf` + `printing` package, native share sheet.
14. **Push notifications.** Wire `firebase_messaging`; backend job for transactional pushes (any social-feature pushes wait until social features exist).
15. **Privacy / data-deletion flow** — explicitly out of scope of the design session. Worth its own grill before App Store submission since both stores now require an in-app "delete my account" path.
16. **Store submission prep** — Apple Developer ($99/yr), Google Play Developer ($25 once), signing keys, privacy disclosures, screenshots.

## Key Files

- `C:\Users\END-USER\Documents\study-time-tracker\CONTEXT.md` — glossary; read first to understand the project language.
- `C:\Users\END-USER\Documents\study-time-tracker\ARCHITECTURE.md` — updated design doc; banner at top points to ADRs for current decisions.
- `C:\Users\END-USER\Documents\study-time-tracker\docs\adr\0001-flutter-for-mobile.md` … `0008-client-side-pdf-export.md` — every architectural decision with rationale and rejected alternatives.
- `C:\Users\END-USER\Documents\study-time-tracker\backend\src\infrastructure\database\entities\NoteEntity.ts` — the existing notes entity (drift from original ARCHITECTURE.md, now reconciled).
- `C:\Users\END-USER\Documents\study-time-tracker\backend\src\presentation\routes\note.routes.ts` — existing notes routes.
- `C:\Users\END-USER\Documents\study-time-tracker\backend\src\index.ts` — entry point; new routes (`/sync`, `/devices`) get mounted here.
- `C:\Users\END-USER\Documents\study-time-tracker\backend\src\infrastructure\database\migrations\` — destination for the new TypeORM migrations.
- `C:\Users\END-USER\Documents\study-time-tracker\CLAUDE.md` — project conventions; update once `mobile/` exists.
- `C:\Users\END-USER\.claude\projects\C--Users-END-USER-Documents-study-time-tracker\memory\MEMORY.md` — project memory index; `project_social-features-planned.md` is the only entry so far.

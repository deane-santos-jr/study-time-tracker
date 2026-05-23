---
status: proposed
---

# Personal records (PRs) and outbound share cards

v2.0 introduces *Personal Records* — auto-detected "best ever" stats — and *share cards*, 9:16 PNGs the user exports to Instagram / Facebook stories. PR detection runs client-side on session end (offline-first per ADR-0002); a broken PR triggers the celebration variant of the share card. Photos used in cards stay on-device; the backend never sees image bytes. There is no in-app feed, no profile pages, no follow graph in v2.0 — sharing is strictly outbound to existing social platforms.

## Personal Records

Four PR types ship in v2.0:

- `LONGEST_SESSION` — single session with the most effective study time (session duration minus the sum of break durations).
- `MOST_DAILY_TIME` — most effective study time aggregated within one local calendar day.
- `LONGEST_STREAK` — most consecutive local calendar days with at least one completed session.
- `BEST_7DAY_WINDOW` — most effective study time across any rolling 7-day window.

Curated badges and focus-quality PRs (e.g. "most days at focusLevel ≥ 4") are explicitly deferred to v2.1.

## Share cards

- Single aspect ratio: 9:16 (1080×1920) — stories on IG / FB / TikTok / WhatsApp.
- Three templates: `STATS`, `PHOTO_LED`, `PR_CELEBRATION`. The PR template is auto-selected when the just-finished session broke any PR.
- Rendered client-side in Flutter via `RepaintBoundary` → `Image` → PNG bytes, reusing the client-side rendering precedent from ADR-0008.
- Saved to camera roll and / or handed to the native share sheet (`share_plus`). No backend upload.
- Brand mark prints the rebrand domain (ADR-0010) and the app mascot (ADR-0013).

## Session metadata

Cards consume two new optional fields on `Session`:

- `locationFavoriteId` (FK) — picked from the user's `LocationFavorite` list at session save time. Manual chip row UX; no GPS in v2.0.
- `extras` (free text, ≤ 140 chars) — "what I'm having" / "oat latte + a brownie" / etc.

Plus one mobile-only field:

- `photoLocalPath` (mobile Drift only; backend has no column for this) — user picks one photo from gallery or camera at share time. Never uploaded.

## Considered Options

- **Server-side PR detection** — rejected: offline-first means the celebration must fire at session end even on a flaky connection. Server may re-derive as a backstop but is not the primary detector.
- **Cloud-rendered share cards** — rejected: round-tripping stats to a render service for one PNG adds cost, latency, and a new infra dependency. ADR-0008 already proves client-side rendering scales for our use case.
- **Multiple aspect ratios at launch (story + square + 4:5)** — rejected: stories dominate the social-flex medium in 2026; square adds template work for marginal payoff. Defer to v2.1 if users ask.
- **In-app feed / profiles / follow graph** — rejected for v2.0: introduces moderation, abuse reporting, social-graph cold start, and major backend work. Revisit only if outbound-only sharing produces enough demand to justify the surface.
- **Cloud photo upload for cross-device share-card replay** — rejected: aligns with ADR-0002 single-device authority. Once a user has shared to Instagram, the durable copy lives there.
- **Client-side PR detection, local PR storage, 3 templates, local-only photos, outbound-only sharing** — chosen.

## Consequences

- New entity on both backend and mobile: `PersonalRecord { id, userId, prType, value, achievedAt, sessionId }`. One row per `(userId, prType)`. Backend table is a write-through cache; the canonical source is the session set, so PRs are re-derivable.
- New entity: `LocationFavorite { id, userId, name, createdAt }`. Mobile-local first, syncs through the existing batch endpoint (ADR-0004).
- `Session` schema (both backend and mobile): `+ locationFavoriteId? FK`, `+ extras? text`. Mobile adds `+ photoLocalPath? text` — backend does not.
- Session-end flow gains a summary screen with detected PRs and a share button. The PR celebration modal appears inline when any PR is broken.
- `share_plus` added to `pubspec.yaml`. iOS `Info.plist` adds `NSPhotoLibraryAddUsageDescription` (save card) and `NSPhotoLibraryUsageDescription` + `NSCameraUsageDescription` (pick a photo). Android manifest adds `READ_MEDIA_IMAGES`.
- Backend exposes `GET /personal-records`. PR upserts ride the same sync mechanism as sessions; client UUID idempotency (ADR-0002) extends to PR upserts.
- Session deletion / material edit makes affected PR rows stale. v2.0 punts on automatic recomputation — PRs are recomputed lazily next time the user opens the PRs screen. v2.1 may add server-side recomputation triggers.
- Share-card completion analytics are out of scope: we do not track whether the user actually completed the iOS / Android share-sheet flow after tapping share.

## Out of scope (deferred)

- Curated achievement badges (e.g. "Night Owl", "Library Regular").
- GPS-based location auto-detection (Google Places / Apple MapKit).
- Square (1:1) and 4:5 card variants.
- Cloud photo storage and cross-device photo history.
- In-app social: feed, profiles, follow, kudos, comments.

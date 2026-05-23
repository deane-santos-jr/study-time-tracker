---
status: accepted
---

# Cubit + get_it + go_router + layered `lib/core` + `lib/src` structure (mirrors activework-flutter-client)

The Flutter client adopts the architecture proven in the
[Activesystems `activework-flutter-client`](https://github.com/Activesystems-Software-Inc/activework-flutter-client/tree/31b0e89c3bb4452d524750a7340ab1994a6efa51)
repo verbatim: Cubit (`bloc` + `flutter_bloc`) for state management, `get_it`
for DI, `go_router` (with `StatefulShellRoute.indexedStack`) for navigation,
and a strict layered tree:

- `lib/core/{api,configs,utils}` — cross-cutting (envelope types, theme tokens,
  constants, router, DI container, shared helpers).
- `lib/src/domain/{models,repositories,services}` — pure interfaces (`I*` prefix)
  and POJOs. No Flutter / Dio / Drift imports.
- `lib/src/data/{repositories,services}` — concrete implementations
  (`DioApiService`, `TokenStorageService`, interceptors, repository impls).
- `lib/src/presentation/modules/<feature>/{screens,services,widgets}` — each
  feature module owns its Cubit + state (`part of` pattern), screens, and
  widgets. Shared widgets live in `lib/src/presentation/widgets/`.

This supersedes the HANDOFF.md "implementation-detail picks" line that
provisionally named **Riverpod** as the state-management library. Riverpod is
out; Cubit is in. Drift, connectivity_plus, fl_chart, firebase_messaging,
flutter_local_notifications, flutter_foreground_task, pdf/printing remain as
chosen in ADRs 0002 / 0007 / 0008 — they are orthogonal to the
state-management choice.

## Considered Options

- **Riverpod + freezed (original HANDOFF pick)** — rejected. The reference
  repo demonstrates the Cubit pattern is sufficient for the same problem
  shape (auth, REST, secure storage, navigation), and matching an existing
  in-house architecture gives us a known-good template and easier onboarding
  for engineers who already work on `activework-flutter-client`.
- **Plain `setState` + `Provider`** — rejected. Doesn't scale past two or
  three screens; mixes business logic with widget code; offers no analog of
  `BlocListener` for side effects.
- **Cubit + get_it + go_router (this ADR)** — chosen. Mirrors the reference
  architecture file-for-file (`api_response.dart`, `injection_container.dart`,
  `router.dart`, `*_cubit.dart` + `*_state.dart` part-files, `I*` repository
  interfaces).

## Consequences

- The mobile project compiles and runs from `mobile/` (per HANDOFF step 1) as
  the third subproject alongside `backend/` and `frontend/`. Package name is
  `study_time_tracker`; bundle org is `com.studytimetracker`.
- The Study Time Tracker backend uses a flat response envelope
  (`{ success, message, data? }`) rather than the reference's nested
  `{ meta, data }` envelope. `DioApiService` is adapted to parse the flat
  shape but the `IApiService` contract and `APIResponse<T>` / `APIListResponse<T>`
  types are unchanged.
- The reference repo carries a tenant slug (`X-Tenant-Slug`) for multi-tenant
  payroll. Study Time Tracker is single-tenant, so the tenant interceptor is
  not ported. A device-ID interceptor (per ADR-0004) will replace it when
  `/sync` work begins — slot is reserved in `injection_container.dart`.
- `lib/src/presentation/modules/study/` is the home for study-domain modules
  (dashboard, sessions, subjects, semesters, analytics, profile). Each gets
  its own `screens/`, `service/` (cubit + state), and `widgets/` subdirs
  following the reference's `ess/` convention.
- Cubits use the `part 'xxx_state.dart'` pattern; states extend `Equatable`.
- DI is a single `init()` in `core/utils/injection_container.dart` exposing
  `sl` (GetIt). Cubits are registered as factories; services and repositories
  as lazy singletons. `MARK:` comment pairs delimit per-feature sections so
  future modules slot in mechanically.
- `flutter_secure_storage` continues to back the access + refresh tokens and
  `expiresAt`, consistent with HANDOFF item 11. A 30-second expiry buffer is
  applied before requests trigger a proactive refresh via `AuthInterceptor`.
- Documentation conventions (no Activesystems copyright header) and lint
  rules (`flutter_lints`) are the project defaults; this ADR does not alter
  them.

## Out of scope (deferred to future ADRs)

- The full sync engine (ADR-0004), local Drift schema (ADR-0002 follow-up),
  push notification handling (ADR-0007), and PDF export pipeline (ADR-0008)
  are wired into `pubspec.yaml` but not yet integrated in code. They become
  separate implementation tasks once the scaffold lands.
- `json_serializable` / `freezed` codegen: deferred. Initial models use
  hand-written `fromJson` / `toJson`; we will switch to codegen once the
  domain model set stabilises.

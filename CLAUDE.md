# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Study Time Tracker — student-focused time tracking with subjects, semesters, sessions, breaks, analytics, and PDF export. Monorepo with three subprojects:

- `backend/` (Express + TypeORM + MySQL) — the only growing API surface.
- `frontend/` (React 19 + Vite + MUI) — **frozen as of 2026-05-23** per ADR-0001. Critical bug fixes only.
- `mobile/` (Flutter 3.41 + Dart 3.11) — the active client. Layered architecture per ADR-0009 (Cubit + get_it + go_router + `lib/core` / `lib/src` tree, mirroring the Activesystems `activework-flutter-client` reference).

No root package.json — install and run commands inside each subdirectory.

`ARCHITECTURE.md` at the repo root is the canonical design doc (domain model, DB schema, full API spec, component hierarchy). `CONTEXT.md` holds the project glossary. `docs/adr/` holds every locked architectural decision — consult ADRs before designing new features or touching domain shapes.

## Commands

All commands run from the respective subdirectory.

### Backend (`backend/`)
- `npm run dev` — ts-node-dev hot-reload on `src/index.ts`, default port 3000
- `npm run build` — tsc emit to `dist/`
- `npm start` — run compiled `dist/index.js`
- `npm test` — Jest (with ts-jest + supertest)
- `npm run test:watch` / `npm run test:coverage`
- Run a single test: `npx jest path/to/file.test.ts` or `npx jest -t "test name"`
- `npm run migration:run` — apply TypeORM migrations
- `npm run migration:generate -- src/infrastructure/database/migrations/Name` — generate from entity diff
- `npm run migration:revert` — roll back last migration

TypeORM CLI uses `backend/ormconfig.ts` as the DataSource. Migrations live in `src/infrastructure/database/migrations/`.

### Frontend (`frontend/`)
- `npm run dev` — Vite dev server on port **3001** (set in `vite.config.ts`, not the Vite default). Proxies `/api` → `http://localhost:3000` so the frontend hits the backend through the dev server — no CORS round-trip in dev. `allowedHosts: ['.ngrok-free.dev']` is set so ngrok tunnels work out of the box.
- `npm run build` — `tsc && vite build`
- `npm run lint` — type-check only (`tsc --noEmit`); there is no ESLint config in this repo
- `npm run preview` — preview the production build

### Environment
Backend needs `backend/.env` (copy from `.env.example`). Required: `DB_*`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `CORS_ORIGIN`. MySQL database name defaults to `timetracker` with `utf8mb4_unicode_ci`.

Alternatively, run `docker compose up -d` from the repo root to start a MySQL 8.0 container on host port **3307** instead of installing MySQL locally. Copy the root `.env.example` to `.env` to override the default dev credentials, and set `backend/.env` to `DB_HOST=localhost`, `DB_PORT=3307` so the natively-run backend connects to the container.

## Architecture

### Backend — Clean Architecture (strict layer boundaries)
`backend/src/` is split into four layers; dependencies point inward (presentation → application → domain ← infrastructure):

- `domain/` — Pure business logic. `entities/` (User, Subject, Semester, StudySession, Break) and `repositories/` (interfaces only, `IXRepository`). No framework imports here.
- `application/use-cases/` — One class per use case, grouped by feature (`auth/`, `session/`, `subject/`, `semester/`, `note/`, `analytics/`). Each use case depends on repository **interfaces** from `domain/`, not concrete implementations. This is where business workflows live (e.g., `StartSession`, `PauseSession`, `ResumeSession`, `StopSession`).
- `infrastructure/` — Framework-coupled adapters.
  - `database/entities/` — TypeORM `*Entity` classes (distinct from domain entities).
  - `database/repositories/` — Concrete implementations of the domain repository interfaces.
  - `database/migrations/` — TypeORM migration files.
  - `security/` — `JWTService`, `PasswordHashingService`.
  - `config/` — `app.config`, `database.config` (exports `AppDataSource`), `jwt.config`.
- `presentation/` — HTTP transport. `controllers/` instantiate use cases, `routes/*.routes.ts` wire them to Express, `middlewares/` provide `authenticate` (JWT guard), `validator` (Zod), `errorHandler`, `logger`.

Entry point `src/index.ts` initializes `AppDataSource`, mounts all routes under `/api/v1/{auth,semesters,subjects,sessions,analytics,notes}`, and exposes `/health`. Auth flow: JWT access + refresh tokens; all routes except `/auth/register` and `/auth/login` require `Authorization: Bearer <token>`.

When adding a feature, the typical chain is: domain entity (+ repo interface) → TypeORM entity + repository → use case → controller → route. Do not import TypeORM/Express inside `domain/` or `application/`.

### Mobile (`mobile/`)
- `flutter pub get` — install dependencies (Flutter 3.41 / Dart 3.11).
- `flutter analyze` — static analysis (no separate lint step).
- `flutter test` — unit + widget tests.
- `flutter run` — debug build on an attached device/simulator.
- `flutter build apk` / `flutter build ipa` — release artifacts.
- `flutter run --dart-define-from-file=.env` — read `mobile/.env` for build-time vars (`API_BASE_URL`, etc.). Copy `.env.example` to `.env` on first checkout; `.env` is gitignored. Without the flag, `lib/core/utils/constants.dart` falls back to `http://10.0.2.2:3000/api/v1` on Android and `http://localhost:3000/api/v1` elsewhere. One-off override: `flutter run --dart-define=API_BASE_URL=https://<ngrok-host>/api/v1`.

### Mobile — layered Flutter app (ADR-0009)
`mobile/lib/`:
- `main.dart` — initializes `get_it` DI, sets up `MultiBlocProvider`, mounts `MaterialApp.router`.
- `core/api/` — `APIResponse<T>` / `APIListResponse<T>` envelope, `APIErrorResponse`, `httpNoConnectionError`. The backend uses a flat `{success, message, data}` envelope — `DioApiService` parses that shape, **not** the reference's `{meta, data}` shape.
- `core/configs/themes.dart` — design tokens (colours, radii) + Material `ThemeData`.
- `core/utils/` — `constants.dart` (base URL + storage keys), `router.dart` (go_router with `StatefulShellRoute.indexedStack`), `injection_container.dart` (the single `sl` GetIt instance + `init()`), `core_utils.dart`, `context_extension.dart`.
- `src/domain/` — pure interfaces (`I*Repository`, `IApiService`, `ITokenStorageService`) and POJO models. No Flutter / Dio / Drift imports here.
- `src/data/` — concrete adapters: `DioApiService`, `TokenStorageService` (flutter_secure_storage), `AuthInterceptor`, repository implementations.
- `src/presentation/modules/<feature>/` — each feature has `screens/`, `service/` (Cubit + state via `part of`), and `widgets/`. Shared widgets live in `src/presentation/widgets/`.
- DI sections in `injection_container.dart` and provider/route lists are bracketed by `// MARK: <feature>-…-start` / `…-end` comments — keep that convention so future modules slot in mechanically.

When adding a feature on mobile: domain interface + model → data implementation → register in `injection_container.dart` → presentation cubit + state + screens → route entry in `router.dart` → provider in `main.dart`.

### Frontend — feature-organized React SPA
`frontend/src/`:
- `App.tsx` — `BrowserRouter` with public (`/login`, `/register`) and `ProtectedRoute`-wrapped pages (`/dashboard`, `/subjects`, `/semesters`, `/history`, `/analytics`).
- `contexts/AuthContext.tsx` — Auth state, token persistence, login/logout/refresh. Wraps the app.
- `services/` — One Axios service per backend resource (`authService`, `subjectService`, `sessionService`, `semesterService`, `analyticsService`, `noteService`) plus shared `api.ts` (base Axios instance with auth interceptors). Services should call relative `/api/v1/...` paths so the Vite proxy handles dev routing.
- `pages/` — One file per route.
- `components/` — `auth/ProtectedRoute`, `layout/{AuthLayout,MainLayout}`, `timer/Timer`, `history/{EditSessionDialog,DeleteSessionDialog,NoteSessionDialog}` (note that history-related dialogs live under `components/history/`, not under `pages/`).
- `theme/` — MUI theme. `types/index.ts` — shared TS types.
- Key UI deps beyond MUI core: `@mui/x-date-pickers` (date inputs on session/semester forms), `recharts` (analytics charts), `date-fns` (date math). When adding charts or date pickers, prefer these over pulling in a new library.

When adding an endpoint, add the typed call to the matching `services/*.ts` file rather than calling Axios directly from pages.

## Conventions

- TypeScript strict throughout; both projects target ES modules.
- Backend uses `reflect-metadata` (imported at the top of `index.ts`) — required for TypeORM decorators.
- Domain entities and TypeORM entities are deliberately separate types — do not collapse them. Repositories map between the two.
- All API responses follow `{ success: boolean, ... }` shape (see `index.ts` 404 handler and health route).
- The `.github/workflows/` setup runs `anthropics/claude-code-action` on PRs and `@claude` mentions in issues/comments — be aware that PR comments may trigger automated Claude reviews.

## Design System

Always read `DESIGN.md` at the repo root before making any visual or UI decisions in `mobile/` or in the eventual marketing site. The Warm Studygram palette (Pulp / Cocoa Ink / Riso Fig / Matcha Stain / Honeyed / Library Blue / Plum Wine / Clay), the Fraunces / Geist / Caveat type system, the share-card layout, the Margot mascot brief, the motion tokens, and the anti-slop hard rules all live there.

Do not deviate without explicit user approval — and never violate the hard rules (no `#FFFFFF`, no `#000000`, no Inter / Roboto / Space Grotesk, no green-as-growth-primary, no confetti / number-roll on PR celebrations). In `/qa` and `/review` flows, flag any code that doesn't match `DESIGN.md`.

The working brand name is `steeped` (recommended, pending trademark + `.app` domain availability check per ADR-0014). Backup shortlist: `nook`, `brew`, `dorm`, `pip`.

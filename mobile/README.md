# Study Time Tracker — Mobile

Flutter client for the Study Time Tracker backend. Architecture follows
ADR-0009 (Cubit + get_it + go_router) — see `docs/adr/0009-...` and the root
`CLAUDE.md` for the layer rules.

## Prerequisites

- Flutter 3.41 / Dart 3.11
- The backend running locally (`cd ../backend && npm run dev`) on port 3000,
  or a deployed `API_BASE_URL` you can reach from the device/simulator.

## Setup

```bash
flutter pub get
cp .env.example .env   # then edit if you need a non-default API_BASE_URL
```

`.env` is gitignored. Without it, `lib/core/utils/constants.dart` falls back
to `http://10.0.2.2:3000/api/v1` on Android and `http://localhost:3000/api/v1`
elsewhere.

## Common commands

```bash
flutter run --dart-define-from-file=.env   # debug build, reads .env
flutter analyze                            # static analysis (lint replacement)
flutter test                               # unit + widget tests
flutter build apk                          # release Android artifact
flutter build ipa                          # release iOS artifact
```

One-off API override (e.g. ngrok):

```bash
flutter run --dart-define=API_BASE_URL=https://<host>/api/v1
```

## Layout

- `lib/core/` — DI (`injection_container.dart`), router, themes, API envelope.
- `lib/src/domain/` — pure interfaces and POJO models. No Flutter / Dio / Drift
  imports.
- `lib/src/data/` — concrete adapters (Dio, secure storage, repositories).
- `lib/src/presentation/modules/<feature>/` — `screens/`, `service/` (Cubit +
  state via `part of`), and `widgets/`.

When adding a feature, follow the chain: domain interface + model → data
implementation → register in `injection_container.dart` → presentation cubit +
state + screens → route entry in `router.dart` → provider in `main.dart`.
The `// MARK: <feature>-…-start` / `…-end` comment pairs delineate where each
feature slots in.

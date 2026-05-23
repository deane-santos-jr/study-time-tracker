---
status: accepted
---

# Use Flutter for the iOS / Android mobile app

We need a mobile app on both App Store and Play Store. The existing client is a React 19 + MUI web SPA, so Capacitor (WebView wrap) was the cheapest path and was recommended. We chose Flutter anyway, accepting a full Dart rewrite of the frontend in exchange for native performance and a single mobile codebase decoupled from the web app's evolution.

## Considered Options

- **Capacitor wrap of the existing React app** — rejected: would have reused the frontend but produces a WebView app with weaker scroll/keyboard/transition feel.
- **React Native / Expo** — rejected: still requires rewriting MUI and Recharts components, without Flutter's rendering consistency.
- **Flutter** — chosen.

## Consequences

- The React web app is frozen (no new features) and the Flutter app is the only growing client.
- Backend remains a generic REST API; no GraphQL or Flutter-specific layer added.
- Charts (currently Recharts) and PDF export (currently backend-rendered) need Flutter equivalents — `fl_chart` and `pdf`/`printing` are the likely picks, to be decided.

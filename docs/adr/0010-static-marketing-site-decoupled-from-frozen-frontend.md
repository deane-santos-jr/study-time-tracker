---
status: proposed
---

# Static marketing site, decoupled from the frozen React frontend

Share cards emitted from the mobile app (per ADR-0012) print a brand URL. ADR-0001 freezes the React web app at `frontend/`; we will not unfreeze it to add a marketing home. Instead a separate tiny static site (Astro or Next static export) is the destination for that URL — hero, screenshots, App Store + Play Store CTAs.

## Considered Options

- **Print the App Store URL on the card** — rejected: ugly QR / long URL, untrackable, no pre-install pitch.
- **Unfreeze the React app and add marketing routes** — rejected: contradicts ADR-0001, mixes the legacy authed surface with marketing.
- **Self-host a one-page site under the existing Express backend** — rejected: backend repo grows responsibility, no static-asset CDN by default, deploy churn on a marketing change.
- **Standalone static site at a brandable domain** — chosen.

## Consequences

- New subproject (or external repo) holds the marketing site. Repo layout decision deferred until ADR-0014 picks the rebrand and the domain follows.
- Hosting: Vercel / Netlify / Cloudflare Pages free tier. No backend, no auth, no API.
- Card URL is the marketing domain (e.g. `<brand>.app`). The card never links into the legacy `frontend/` auth UI.
- The frozen React frontend remains the only surface for existing web users to log in to view history; it gets a small "Mobile app now available" banner but no other changes. ADR-0001 is unchanged.
- A new ADR would be required if we later decide to deprecate or kill the React app entirely.

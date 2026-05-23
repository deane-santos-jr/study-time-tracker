---
status: proposed
---

# Curated subject color palette (overrides free-form Subject.color)

The current `Subject` entity exposes a free-form color (any hex). For v2.0's playful-cartoon brand, color is a brand asset: mascot, illustrations, achievement banners, and share-card templates all assume backgrounds drawn from a known palette. We replace the free-form color picker with a curated brand palette and snap existing subject colors to nearest brand color on migration.

## Considered Options

- **Keep the free-form color picker** — rejected: arbitrary user colors break mascot / illustration contrast and force every share-card template to handle every possible hue.
- **Curated palette but free hex as override** — rejected: defeats the cohesion goal the moment one user enables the override.
- **Single accent color, no per-subject color** — rejected: subjects need visual distinction in lists and analytics charts.
- **Curated brand palette of ~6 colors, subject picks one** — chosen.

## Consequences

- Brand palette is the single source of truth for color tokens. Defined in `mobile/lib/core/configs/themes.dart`, mirrored in backend seed data and the static marketing site (ADR-0010).
- `Subject.color` column stays as a string but values are now constrained to the palette enum. Backend validates on write; clients pick from a chip row, not a hex picker.
- One-time migration: nearest-color snap (CIE Lab distance) for each existing `Subject` row. Pre-launch product, so the data set is small — a single backfill script run during the v2.0 deploy.
- Mascot illustrations, achievement banners, and share-card templates may freely use any palette color knowing every subject will harmonize with it.
- Adding a new brand color in the future requires updating the enum on both client and server plus regenerating illustration variants — not free.
- The exact palette (hex values, names) is out of scope for this ADR and is settled during design exploration (`/design-consultation`).

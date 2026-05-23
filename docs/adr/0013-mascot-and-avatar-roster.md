---
status: proposed
---

# App mascot + curated user avatar roster

v2.0 introduces character work as a first-class brand asset. One app mascot represents the brand (empty states, loading screens, the lower-right brand mark on share cards per ADR-0012). Each user picks an avatar from a curated roster of ~12 designed characters — no procedural avatar creator, no photo upload.

## Considered Options

- **No characters; identity is initials + accent color** — rejected: contradicts the playful-cartoon brand direction; share cards would feel anonymous.
- **App mascot only, no user avatar** — rejected: user identity on share cards collapses to a name string, which doesn't carry the polish the rest of the card targets.
- **Bitmoji / Memoji / Ready Player Me-style avatar creator** — rejected: avatar creators are entire products. Out of scope for v2.0.
- **App mascot + ~12-character curated roster for users** — chosen.

## Consequences

- The roster is delivered as static SVG / vector assets bundled with the mobile app — no server fetch, no per-user licensing, no CDN dependency.
- `User` entity gains `+ avatarId` (enum-style string, e.g. `roster_07`) and `+ displayName`. Email-based identity (ADR-0001 / ADR-0009 auth flow) is unchanged.
- Avatar picker is a single screen with a 3-column grid of characters. No pagination needed at 12 characters.
- Brand mascot is *not* selectable; it appears as the share-card brand mark and is rendered identically across all users.
- Mascot identity (archetype, name, color) is out of scope for this ADR — design exploration (`/design-consultation`, `/design-shotgun`) picks it. Hard constraint: must not be an owl (Duolingo trade dress) or any other archetype dominantly owned by an existing study / productivity brand.
- Roster expansion in the future is a code release (asset bundle) — not a hot-pluggable system. Acceptable given the gen-z personalization expectation in our segment is "characters with vibes," not "infinite variants."
- Pre-launch, so existing users default to `roster_01` on first launch of v2.0; first-run onboarding prompts a pick.
- All character assets must work against the curated brand palette (ADR-0011) — illustrators / generators must be briefed with the palette before producing variants.

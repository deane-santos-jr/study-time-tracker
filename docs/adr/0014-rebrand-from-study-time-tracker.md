---
status: proposed
---

# Rebrand from "Study Time Tracker" to a new memorable name

The utility name "Study Time Tracker" served v1 as an honest descriptor. For v2.0 — a social study product with a mascot (ADR-0013), share cards going to Instagram (ADR-0012), and a marketing landing page (ADR-0010) — recall and brandability matter more than literal accuracy. The product rebrands to a new 1–2-syllable name, picked through design exploration with trademark + domain filtering. This ADR locks the *decision* to rebrand; the chosen name itself is recorded in a follow-up amendment to this file once selected.

## Considered Options

- **Keep "Study Time Tracker"** — rejected: weak recall, awkward on a share-card brand mark, no available short-form domain.
- **Hybrid (short brand name + "Study Time Tracker" tagline)** — rejected: doubles the brand surface to maintain; share-card brand-mark space is too tight to print both legibly.
- **Rebrand to a new memorable name, chosen via design exploration** — chosen.

## Selection criteria (for design exploration)

- 1–2 syllables.
- Not a registered trademark in the App Store productivity / education categories.
- `.app` or `.com` domain available, or acquirable within budget.
- Valid as a Flutter / package namespace (`com.<brand>`, lowercase, no hyphens, no leading digit).
- Evokes focus / study / time / growth — not an exotic word that needs explanation in onboarding.
- Looks correct lowercased in body copy *and* uppercased as a brand mark.

## Consequences

- Flutter package name changes (`study_time_tracker` → new). Requires:
  - Edit of `pubspec.yaml`, `mobile/android/app/build.gradle.kts` `applicationId`, `mobile/ios/Runner.xcodeproj/project.pbxproj` bundle ID, and all `package:study_time_tracker/...` imports across `mobile/lib/`.
  - This ADR supersedes the package-name and bundle-org choices in ADR-0009. ADR-0009's other architecture decisions (Cubit + get_it + go_router + layered tree) remain in force unchanged.
- iOS bundle org changes (`com.studytimetracker` → `com.<brand>`).
- Backend repo + module names are unchanged — the backend has no end-user-visible brand, so renaming would be churn.
- App Store + Play Store listings are created under the new name. There are no existing listings to migrate.
- The new domain (for the static marketing site, ADR-0010) is purchased *before* the App Store listing is submitted, to avoid a "name reserved but inactive" gap.
- The frozen React frontend (ADR-0001) keeps its current "Study Time Tracker" branding for the small remaining web user surface. A new ADR would be required to rebrand it in place.
- Once the name is chosen, this ADR is amended in place (not superseded) with the final name and the date selected. Cross-references in ADR-0009, ADR-0010, ADR-0012, ADR-0013 update at the same time.

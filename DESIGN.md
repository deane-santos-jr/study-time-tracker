# Design System — steeped (working name)

**Status:** Draft, locked via `/design-consultation` 2026-05-24. The name `steeped` is recommended pending App Store productivity-category trademark check and `.app` domain availability check.

The system is named **Warm Studygram** — a playful, character-led, paper-touched aesthetic shaped by the studygram / studytok lineage rather than the Duolingo / Headspace lineage of "playful cartoon" we originally locked in the grilling session. Departure rationale: the user's north-star answer (below) made it clear achievability matters more than celebration.

## North Star

> **"I can do that too — and I'd be proud to share it."**

Every design decision serves this. Viewers of a share card on Instagram should react with *quiet recognition and achievability*, not *transcendent impression*. The card is the friend's good day, not the Olympic record.

## Product Context

- **What this is:** A solo-first study session tracker for gen-z students. Personal records (longest session, daily total, longest streak, best 7-day window) are auto-detected and exportable as polished 9:16 cards to Instagram / FB stories. No in-app feed, no follow graph — sharing is outbound only.
- **Who it's for:** Students, college-leaning. High-school to early-career welcome. Audience identifies with the studygram / studytok culture — romanticized but real, cozy main-character energy.
- **Space/industry:** Productivity + study + outbound-social. Adjacent to Forest, Flora, Pomofocus, Brain.fm, Notion. Mechanic shares with Strava; *aesthetic* shares with studygram.
- **Project type:** Native mobile app (Flutter, iOS + Android) + 1-page static marketing site at the eventual rebrand domain.

## Aesthetic Direction

- **Direction:** Warm Studygram — playful cartoon shaped by café-zine warmth.
- **Decoration level:** Intentional. Paper-grain on surfaces, hand-drawn café vignettes for empty states and onboarding, soft washi-tape accents on certain cards, handwritten margin notes for "personal best" moments only.
- **Mood:** Cozy lived-in. The app should feel like a café notebook someone with great taste would actually keep. *Not designed — made.*
- **Reference reads:** Flora (`flora.appfinca.com`) for closest existing aesthetic match. Forest (`forestapp.cc`) as cautionary — too sterile, no character. Duolingo for mascot integration patterns but their bright-saturated energy is rejected. Strava share cards are the explicit anti-pattern for the share card framing (transcendence vs. our proximity).

## Typography

All fonts are free. No paid licenses required.

- **Display / Hero / PR statements:** **Fraunces** (Google Fonts, variable). Used in italic at most display sizes — friendly serif with character, soft warmth, opsz axis lets it scale from intimate to dramatic. *Rationale:* a friendly italic serif sets the studygram tone immediately and refuses the "tech sans" default every other study app picks.
- **Body / UI / Labels:** **Geist** (OFL, Vercel). Humanist sans, warmer than Inter, has tabular-nums and a Mono sibling. *Rationale:* warm enough for cozy framing, sharp enough for stats, broadly readable.
- **Tabular / Stats / Timers:** **Geist** with `font-variant-numeric: tabular-nums`. *Rationale:* same family DNA as body, but with the satisfying tick of fixed-width digits when timers run.
- **Mono / Dates / Code (rare):** **Geist Mono** (OFL). *Rationale:* family consistency.
- **Handwritten accent:** **Caveat** (Google Fonts). *Single role only* — "personal best" / margin-note scribbles. **Never in UI chrome.**
- **Loading strategy:** Google Fonts CDN via `<link>` on the marketing site; Flutter app bundles the font files in `assets/fonts/` and registers them in `pubspec.yaml`.
- **Modular scale (base 16px, ratio ~1.25):**

  | Token | Px | Use |
  |---|---|---|
  | `xs`   | 12 | Mono labels, fine print |
  | `sm`   | 14 | Secondary body, captions |
  | `md`   | 16 | Body default |
  | `lg`   | 18 | Emphasized body, list items |
  | `xl`   | 22 | Subhead, card titles |
  | `2xl`  | 28 | Section titles (Fraunces italic) |
  | `3xl`  | 36 | Screen titles |
  | `4xl`  | 56 | Card headlines (Fraunces italic, share-card PR sentence) |
  | `5xl`  | 96 | Big stats (Geist tabular-nums, share-card hero number) |
  | `hero` | 120+ | Marketing-site hero only |

## Color

- **Approach:** Multi-color brand palette + warm chrome. *No green-as-growth as primary.* Color is paper-touched, never pure / screen-bright.
- **Brand colors** (subjects pick exclusively from this palette per ADR-0011):

  | Role | Name | Hex | Use |
  |---|---|---|---|
  | Subject 1 / primary | **Riso Fig** | `#A23B5C` | Dusty raspberry. Used sparingly — only the share-card hero number + key primary actions. |
  | Subject 2 | **Matcha Stain** | `#7A8C3E` | Tea-residue green. Earthy. *Not* "growth green." |
  | Subject 3 | **Honeyed** | `#E8A33D` | Marigold with brown undertone. Warm. |
  | Subject 4 | **Library Blue** | `#3E5C7A` | Dusty cobalt. Well-loved book cloth. |
  | Subject 5 | **Plum Wine** | `#6E4F7A` | Evening study purple. Quiet. |
  | Subject 6 | **Clay** | `#C56D5C` | Terracotta. Afternoon-light warmth. |

- **Chrome:**

  | Role | Name | Hex | Use |
  |---|---|---|---|
  | Surface | **Pulp** | `#F4ECD8` | Warm cream paper. **NEVER `#FFFFFF`.** |
  | Ink | **Cocoa Ink** | `#2B221C` | Soft black with brown undertone. **NEVER `#000000`.** |

- **Semantic colors** (reuse brand palette, don't invent new):
  - Success: Matcha Stain `#7A8C3E`
  - Warning: Honeyed `#E8A33D`
  - Error: Clay `#C56D5C` (deepened to `#A85643` for high-contrast surfaces)
  - Info: Library Blue `#3E5C7A`
- **Opacity scale on ink:** 100% (`#2B221C`), 70% soft, 45% faint, 25% hint. Use these instead of additional grays.
- **Dark mode — "Reading Lamp":**
  - Surface: `#1E1814` (warm near-black, café-at-night). **NEVER pure black.**
  - Ink: `#F4ECD8` (Pulp inverted).
  - Brand colors deepen ~5–10% saturation for survival against the dark surface:
    - Riso Fig → `#C95778`
    - Matcha Stain → `#9DAE5C`
    - Honeyed → `#F0B658`
    - Library Blue → `#6889A8`
    - Plum Wine → `#8E6D9A`
    - Clay → `#D88472`
  - Mood: morning-café (light) → evening-desk-lamp (dark). Not a tonal inversion — a *time-of-day shift*.

## Spacing

- **Base unit:** 4px.
- **Density:** Comfortable — generous around content blocks, tight inside cards.
- **Scale:**

  | Token | Px | Common use |
  |---|---|---|
  | `2xs` | 2  | Hairline gaps |
  | `xs`  | 4  | Tight inline spacing |
  | `sm`  | 8  | Stacked label / control |
  | `md`  | 16 | Card padding default |
  | `lg`  | 24 | Section internal spacing |
  | `xl`  | 32 | Section gap |
  | `2xl` | 48 | Major section break |
  | `3xl` | 64 | Screen-level major break |
  | `4xl` | 96 | Marketing-site only |

## Layout

- **Approach:** Hybrid. **Grid-disciplined inside the app** (M3 baseline, predictable alignment, single-column phone layouts), **editorial / composition-first on share cards** (asymmetric, eye-path-led).
- **Grid:**
  - Mobile: single column, 16px outer padding, no fixed gutter.
  - Marketing site: max content width `1120px`, 12-col grid, 24px gutter on desktop.
- **Border radius (rounded, not bubbly):**

  | Token | Px | Use |
  |---|---|---|
  | `sm`   | 8    | Chips, tags, small inputs |
  | `md`   | 16   | Cards, list items |
  | `lg`   | 24   | Hero cards, share-card outer corner |
  | `xl`   | 32   | Phone-frame mockups, marketing site large cards |
  | `full` | 9999 | Pills, buttons, avatar circles |

## Share Card — The Money Artifact

Locked specification for the **9:16 (1080×1920)** share card. Per ADR-0012 the card renders client-side via `RepaintBoundary` → `Image` → PNG.

### Three templates (per ADR-0012 Q8)

1. **`PR_CELEBRATION`** — auto-selected when any PR was broken by the just-finished session. Headline is the PR sentence in Fraunces Italic.
2. **`STATS`** — daily / weekly summary. No specific PR called out. Headline is a Fraunces Italic descriptor ("today's focus" or similar).
3. **`PHOTO_LED`** — the user attached a photo. The photo sits as a 4:3 polaroid-style card, slightly rotated (~2°), with a paper-grain overlay. Stats stack below.

### Eye-path layout (`PR_CELEBRATION` reference)

The card is designed so the viewer's eye lands on the **human first**, then the **stat**, then the **cozy detail**. Stat sandwiched between intimacy.

```
[top 15%]   Pulp paper. Tiny illustrated mug + lowercase date
            in Geist Mono 11pt at 60% ink opacity.

[middle 50%] PR sentence in FRAUNCES ITALIC, left-aligned, ~56pt,
            up to 3 lines.
            E.g. "longest focus session — 2h 47m on data structures"

            BIG STAT in Geist tabular-nums, ~96pt, Riso Fig color.
            E.g. "2:47"

            CAVEAT scribble at ~26pt, Riso Fig, rotated ~-3°.
            E.g. "personal best"

[bottom 25%] Avatar (36–60px circle) · @handle (Geist 14–20pt, semibold)
            · "Starbucks Ortigas · oat latte + a brownie"
              (Geist 12–14pt, Cocoa Ink at 70% opacity)
            · optional 4:3 polaroid photo, slight rotation, paper-grain
              overlay if PHOTO_LED

[bot-right]  Mascot mark (22–40px) + lowercase italic wordmark
            (Fraunces Italic 14pt or Geist Mono).
```

### Anti-patterns for the card

- Never the Strava layout: giant centered number, tiny brand, dark background, all-caps "PR" overlay.
- Never confetti, glitter, or shiny gradient overlays.
- Never an all-caps headline.
- Never centered the entire card vertically.
- Never crop the avatar smaller than 32px.

## Mascot — Margot, the Café Regular

Per ADR-0013. Not an animal. **A young person in an oversized cardigan, sitting in a different corner of the same imaginary café each day with a different drink. Same face, different outfit, different order.** She appears in empty states, loading screens, and as the lower-right brand mark on share cards. The achievability framing made literal — the mascot is a student on a good day, not a guru.

User avatars (per ADR-0013, 12-character curated roster) are **12 *other* café regulars in the same illustration style** — Margot's friends, all studying at the same café in different corners. Same illustrative voice, different bodies, different vibes.

**Hard constraints on the mascot/avatar illustration brief:**

- Hand-drawn-feel. Pencil-and-watercolor or soft-fill flat illustration. **NOT 3D-rendered. NOT photorealistic. NOT Memoji-style.**
- Faces are gentle, low-detail (avoids uncanny-valley at small sizes).
- Each character has a recurring "vibe" — outfit, drink, posture — that the user can identify with.
- All character work must read correctly against any of the 6 brand colors as backdrop (per ADR-0011) and against Pulp / `#1E1814` surfaces.
- Final illustrations come from `/design-shotgun` (or an external illustrator) — the SVG stubs in `/tmp/design-consultation-warm-studygram.html` are scaffolding, not the final art.

## Motion

- **Approach:** Intentional. Spring-based for navigation and ordinary state transitions; **deliberately restrained for PR celebrations.**
- **Easing tokens:**
  - `enter`: `Curves.easeOutCubic`
  - `exit`: `Curves.easeInCubic`
  - `move`: `Curves.easeInOutCubic`
  - `spring`: `SpringDescription(mass: 1, stiffness: 180, damping: 18)` (gentle bounce)
- **Duration tokens:** `micro` 80ms · `short` 200ms · `medium` 350ms · `long` 500ms · `paper-fold` 700ms (PR celebration only).
- **PR celebration specifically:** **No confetti. No number-roll-up. No bounce.** The PR card *arrives* via a single paper-unfold rotation (700ms `enter` curve, single 4° rotateY plus a soft fade-in). The restraint *is* the celebration. Anti-pattern: anything resembling a slot machine.
- **Navigation transitions:** `slideIn` from right (push) / fadeThrough (replace) — Flutter `MaterialPageRoute` baseline tuned with the tokens above.

## Implementation tokens (`mobile/lib/core/configs/themes.dart`)

The brand tokens above are codified in `mobile/lib/core/configs/themes.dart`. Suggested constants:

```dart
// Brand palette (sealed enum / static const)
const kPulp        = Color(0xFFF4ECD8);
const kCocoaInk    = Color(0xFF2B221C);
const kRisoFig     = Color(0xFFA23B5C);
const kMatchaStain = Color(0xFF7A8C3E);
const kHoneyed     = Color(0xFFE8A33D);
const kLibraryBlue = Color(0xFF3E5C7A);
const kPlumWine    = Color(0xFF6E4F7A);
const kClay        = Color(0xFFC56D5C);

// Dark variants
const kPulpNight       = Color(0xFF1E1814);
const kRisoFigNight    = Color(0xFFC95778);
// ... etc
```

Fonts are bundled as assets, registered in `pubspec.yaml`:

```yaml
fonts:
  - family: Fraunces
    fonts:
      - asset: assets/fonts/Fraunces-Italic-VariableFont.ttf
        style: italic
      - asset: assets/fonts/Fraunces-VariableFont.ttf
  - family: Geist
    fonts:
      - asset: assets/fonts/Geist-Regular.ttf
      - asset: assets/fonts/Geist-Medium.ttf
        weight: 500
      - asset: assets/fonts/Geist-SemiBold.ttf
        weight: 600
  - family: GeistMono
    fonts:
      - asset: assets/fonts/GeistMono-Regular.ttf
  - family: Caveat
    fonts:
      - asset: assets/fonts/Caveat-SemiBold.ttf
        weight: 600
```

## Anti-slop hard rules (enforce in QA + code review)

- Never `#FFFFFF` — use Pulp `#F4ECD8`.
- Never `#000000` — use Cocoa Ink `#2B221C`.
- Never Inter, Roboto, Arial, Helvetica, Open Sans, Lato, Montserrat, Poppins, Space Grotesk, system-ui as the display or body font.
- Never green as primary brand color (the anti-Forest constraint).
- Never confetti, sparkles, number-roll-up, or slot-machine motion for celebrations.
- Never "great job!" sticker stack or any infantilizing copy.
- Never a 3-column SaaS feature grid on the marketing site.
- Never a purple gradient as a primary action.
- Never an all-caps brand mark or all-caps "PR" overlay on the share card.
- Never crop the user-avatar smaller than 32px on the share card.
- Never use the mascot as a "scolding" presence (no error states where Margot looks disappointed).

## Brand name

**Working name: `steeped`** (`steeped.app` pending availability check).

Selection criteria (per ADR-0014):
- 1–2 syllables.
- Not a registered trademark in App Store productivity / education categories.
- `.app` or `.com` domain available within budget.
- Tokenizable as a Flutter / package namespace (`com.<brand>`, lowercase, no hyphens, no leading digit).
- Evokes focus / study / time / coziness.
- Looks correct lowercased in body copy *and* italic-uppercased as the brand mark.

Backup shortlist if `steeped` is taken or trademarked:
1. `nook` — cozy corner.
2. `brew` — coffee + study (collision risk with Homebrew the package manager).
3. `dorm` — claims a place; college-coded.
4. `pip` — tiny, friendly (collision risk with Python pip).

Once the trademark + domain checks come back, amend ADR-0014 in place with the final name and update this DESIGN.md.

## Two deliberate departures from category norms (the risks we took)

1. **No green-as-growth as the primary brand color.** Every study / focus app uses green (Forest, Habitica, Notion calendar, fl_chart defaults). Our primary is Riso Fig — warm dusty raspberry. The card communicates *café*, not *gym*; *cozy*, not *virtuous*.
2. **No celebratory motion (paper-fold instead of confetti).** Every gamified study / fitness app deploys confetti / number-roll / sparkles on PR. We don't. The PR card simply *unfolds*. Restraint reads as taste, not coldness. This is the biggest pull-back from the original Q11 "bouncy motion" brief in the grilling session.

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-05-23 | 16 product decisions locked via `/grill-me` | Pivot from solo study tracker → solo-first with outbound-only social. Mascot + 12 avatars, multi-color palette, M3 expressive, 9:16 share cards, 3 templates, 4 PR types, manual location, local-only photos, big-bang v2.0, rebrand. |
| 2026-05-23 | ADRs 0010–0014 drafted | Marketing site (0010), palette (0011), PRs + cards (0012), mascot + avatars (0013), rebrand (0014). |
| 2026-05-24 | Direction shifted from "Duolingo lineage" to "studygram zine" | North star answer ("I can do that too — and I'd be proud to share it") revealed that Duo-bright celebration framing risks reading as kid-app; warmer, quieter direction better serves achievability framing. Departure from Q11 explicitly acknowledged. |
| 2026-05-24 | Warm Pulp palette + Fraunces / Geist / Caveat type system | Free fonts, paper-touched colors. Inspired by Claude subagent's "Cozy Zine" proposal (paid-font version adapted to free equivalents). |
| 2026-05-24 | Mascot archetype: Margot (café regular human, not an animal) | The achievability framing made literal — the mascot is a student, not a guru. Rejected: capybara (too Duolingo-adjacent), no-mascot-only-desk (weaker for merch / brand mark). |
| 2026-05-24 | Working name: `steeped` (pending availability) | Verb form, café/tea metaphor, studygram-coded, 1 syllable, package-name safe. Backup shortlist documented. |
| 2026-05-24 | DESIGN.md initialized | Source of truth for all visual decisions. Referenced from CLAUDE.md to be loaded by all future Claude sessions. |

## What's NOT in this DESIGN.md yet

Out of scope for v0.1 — to be added as design exploration continues:

- Specific empty-state illustration set (12+ scenes featuring Margot).
- Onboarding flow storyboard (meet-the-mascot → pick-your-avatar → create-first-subject → privacy-primer).
- Subject icon set (study-specific glyphs that pair with the palette).
- Analytics chart styling (the `fl_chart` overrides for line / bar charts).
- PDF export styling (per ADR-0008 — branded but readable for academic submission).
- Marketing-site full design (1-page Astro / Next static site at the eventual domain).
- Notification copy and tone-of-voice rules.
- Microcopy / error-state copy guide.

Each becomes a follow-up in design exploration once the first implementation lands.

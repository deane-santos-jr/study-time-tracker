---
status: accepted
---

# Mobile IA pivot — terms screen as the setup home, history as a peer of stats

The original mobile IA mirrored the v1 frontend almost 1:1: `dashboard`, `subjects`, `semesters`, `analytics` as four sibling top-level destinations. Once ADR-0015 (semester optional via ad-hoc) landed, that shape stopped working. Subjects and semesters were no longer parallel concerns — every subject lives inside a term, and the only useful question on a "subjects" screen was "which term's subjects?" The two destinations double-counted the same data, and the user had to mentally reconcile "where do I go to add a subject?" against "where do I go to make a new term?" There was also no visible history surface at all — sessions vanished after the dashboard's recent-sessions strip scrolled past them.

The pivot collapses subjects into the terms screen, introduces a first-class history tab, and rewords the bottom nav to match the home tile's vocabulary. The result is a four-destination shell that maps cleanly to the four jobs a student actually does: study right now (today), look back at what you did (history), see the totals (stats), and manage your account (you). Term-and-subject *setup* moves into the AppBar's `…` overflow on the dashboard and the `make active` flow on the terms screen — it is no longer a primary bottom-nav destination because it is not a primary daily action.

## Considered Options

- **Keep the four parallel destinations (dashboard / subjects / semesters / analytics)** — rejected. After ADR-0015 subjects and semesters are no longer parallel concerns; the IA double-counted data and forced the user to context-switch between two screens that describe the same hierarchy.
- **Drop the terms destination entirely; surface terms only via the dashboard pill** — rejected. The pill is good for *switching* terms, not for managing them (renaming, deleting, editing the subjects inside). Hiding the only management surface behind a small pill makes term editing un-discoverable.
- **Tab-based subjects/semesters within a single screen** — rejected. Two flat lists side-by-side reproduces the original IA confusion in a smaller container; doesn't communicate the parent-child relationship.
- **Merge subjects under terms as a chip-row roster, promote history to bottom nav, hide setup behind dashboard overflow (this ADR)** — chosen. Matches the hierarchy that ADR-0015 made the canonical mental model; gives history a first-class home; aligns the four destinations with the four daily jobs.

## Bottom nav vocabulary

The four destinations are now `today / history / stats / you`. Each label is lowercase per the DESIGN.md anti-slop rules. The rename is deliberate — these are nouns the user thinks in, not module names from the codebase:

- **today** (`/dashboard`) — the home tile, where you start a session
- **history** (`/history`) — list of finished sessions, newest first; ad-hoc rendered with soft-ink dot
- **stats** (`/analytics`) — totals and trends (currently placeholder; fl_chart screens land here)
- **you** (`/profile`) — account, sign-out, eventually privacy / data export (currently placeholder)

The floating dark pill nav (`study_shell_screen.dart`) and the ≥96 px bottom-padding reserve on scrollable bodies are unchanged from the home-tile pattern.

## `/semesters` becomes the unified terms screen

The terms screen (`mobile/lib/src/presentation/modules/study/semesters/screens/semesters_screen.dart`) is now the single place to set up the study environment. It is reachable from the dashboard's AppBar overflow (`…`) and from the `ActiveSemesterPill` on the dashboard. It is **not** in the bottom nav — setup is not a daily action.

Layout:

- A horizontally-scrolling chip row of terms at the top (`_TermChip`), with a `+ add a term` chip appended.
- The selected term's subjects render below as `SubjectTile` rows, with per-subject totals fed by `DashboardStatsCubit`.
- An AppBar overflow menu on each term provides `edit` (opens `semester_form_sheet`) and `delete`. The active term cannot be deleted (UI block + server validation, per ADR-0015).
- A `_MakeActivePill` row below the term name handles activation, replacing the old card-tap-to-activate gesture.
- Subject CRUD is inline within the term: the `_SubjectsSection` in `semester_form_sheet.dart`'s edit mode is the canonical entry point. `showSubjectEditSheet()` is a slim name+color edit sheet exposed from the same module.

## `/subjects/new` and `/subjects/:id` are removed

Subject editing no longer has its own routes. The full-screen `SubjectFormScreen` and the orphaned `SubjectsListScreen` / `SemesterCard` widgets were deleted in the same commit as the IA pivot. Subjects are created and edited via:

- `subject_form_sheet.dart` (full sheet, used from the dashboard's `+` affordance when no subjects exist yet)
- `semester_form_sheet.dart`'s inline `_SubjectsSection` (used from the terms screen)
- `showSubjectEditSheet()` (slim edit, name + color only)

This keeps every subject action contextual to its parent term — there is no longer a "global subjects list" because the term *is* the list.

## Ad-hoc affordance moves under the start button

Per ADR-0015, the dashboard had a `+ something else` row inside the subject picker for starting an ad-hoc session. That row is removed (`_AdHocRow` deleted from `subject_selector.dart`). Ad-hoc is now a peer toggle under the start button (`session_tile.dart`):

- When subjects exist and the picker is closed, a `+ independent activity` link appears below `start`.
- Tapping it swaps the picker for an activity-name text field and a `use a subject instead` link to swap back.

The previous IA buried ad-hoc inside a list of subjects, making it visually equivalent to "subject number N+1." The new placement makes ad-hoc a distinct *mode*, which matches the data model (subject_id XOR activity_name).

## `SubjectsCubit` is no longer term-scoped

`SubjectsCubit.loadForSemester(String?)` becomes `SubjectsCubit.load()`. The cubit returns every subject the user owns, and consumers filter by the active term at the call site (the dashboard filters by `activeSemesterId`; the terms screen filters by the chip-selected term). The shell-level `BlocListener<SemestersCubit>` that previously called `loadForSemester` when the active term changed is removed.

Rationale: subjects are a stable, user-scoped list — there is no point re-fetching them every time the active term changes. Filtering is cheap on the client, refetching is not. This also unblocks the history screen, which needs every subject (including ones from past terms) to resolve `subjectId → name` for rendering.

`SubjectsLoaded.semesterId` is dropped from the state.

## `ActiveSemesterPill` moves to the "your subjects" header

Previously the pill lived in the dashboard's `AppBar` title slot. It now sits inline with the `your subjects` section header. The AppBar is reduced to a `…` overflow with `manage terms` and `sign out`. Reason: the home tile (the timer card) is the primary focal point of the dashboard; the AppBar should not compete with it for visual weight. A pill in the section header reads as "what's active" without dominating the screen.

The pill also gains a `+ add a term` affordance when no term is active, plus an `isLoading` state for the initial fetch.

## History screen

A new `/history` route renders the user's sessions newest-first. The screen joins `HistoryCubit` (sessions list) against `SubjectsCubit` (id → name + color lookup) and renders each row through `PulpTile`. Ad-hoc sessions get a soft-ink square dot (per DESIGN.md "absence of color is the ad-hoc signal") and their `activityName` as the label. The session counter ("N sessions") replaces a heavier list header; pull-to-refresh re-fetches.

Empty state copy: `start a session from the home tab — it lands here when it ends.`

Test coverage: `mobile/test/history_cubit_test.dart` (4 `blocTest`s — sort order, empty list, ad-hoc preservation, repository error).

## Consequences

- The mobile shell has exactly four bottom-nav branches. Adding a fifth requires either replacing one or moving to a different nav pattern; both are scope-creep decisions that warrant a new ADR.
- Setup (terms + subjects) is one screen away from the dashboard. New users see no subjects on the dashboard and tap `…` → `manage terms` (or the pill's `+ add a term`) to bootstrap.
- The `…` AppBar overflow becomes the canonical "secondary actions on the home tile" surface. Future entries (export PDF, share card, settings) slot in here, not into the bottom nav.
- `SubjectsCubit.load()` is now called once at shell mount and never again unless the user explicitly refreshes via pull-to-refresh on a consuming screen. This is a soft cache; if a subject is created from the terms screen, the cubit's success handlers patch the state directly.
- The deleted `SubjectFormScreen`, `SubjectsListScreen`, and `SemesterCard` are gone for good. Any future need for a full-screen subject editor should compose the existing sheets in a `Scaffold` rather than resurrect those files.
- Future work — when the share-card editor lands, it gets its own route reachable from the `…` overflow, not a fifth bottom-nav slot. When `/profile` becomes a real screen, the data-deletion + sign-out actions migrate there from the dashboard overflow.

Implementation shipped in commit `e2eaf65 feat(mobile): IA pivot — history tab, unified terms screen, subjects decoupled` on branch `mobile--warm-studygram-foundation`.

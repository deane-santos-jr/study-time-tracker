---
status: accepted
---

# Semester optional via ad-hoc activity escape valve

v1 modeled semesters as a hard prerequisite — every subject required a semester, every session required a subject, every subject's lifetime ended when its semester was deleted. The grilling for v2.0 surfaced two failure modes: (1) the **fresh-user empty state** forced semester creation before the first session, breaking the "open and start studying" affordance the home tile promises (DESIGN.md), and (2) the **off-curriculum studier** (bootcamp learners, hobbyists, post-grads) had no way to use the app at all.

Two paths considered: a **positioning shift** (drop semesters entirely, become a generic study tracker), or a **flexibility tweak** (keep semesters as an organizing primitive but add an escape valve). We chose the tweak: semesters remain the canonical container, but `sessions.subject_id` becomes nullable and a free-text `activity_name` field carries the "what are you doing right now" signal when no subject is selected. The `"+ something else"` row in the dashboard's subject picker is the entry point — DESIGN.md "anti-slop" rules apply (lowercase, Cocoa Ink, no chip color in running state because the *absence* of color is the ad-hoc signal).

## Considered Options

- **Drop semesters; rename to a generic tracker** — rejected: invalidates v2.0 positioning (the share card, mascot, and "your subjects" home tile all assume a curated set of named focus areas), and the existing user base mapped subjects to coursework.
- **Make semesters truly optional (subjects also nullable)** — rejected: subjects without a semester have no logical home in the app's information architecture (the dashboard groups by subject under semester context); pushes complexity into every screen.
- **Keep schema strict, add an "uncategorized" sentinel subject per user** — rejected: pollutes the subjects list and the analytics aggregation; users would see "uncategorized" in their share cards.
- **Nullable `subject_id` + `activity_name` field, with a CHECK invariant** — chosen.

## Schema change

```sql
ALTER TABLE sessions
  MODIFY subject_id   VARCHAR(36) NULL,
  MODIFY semester_id  VARCHAR(36) NULL,
  ADD COLUMN activity_name VARCHAR(100) NULL,
  ADD CONSTRAINT sessions_subject_or_activity CHECK (
    (subject_id IS NOT NULL AND activity_name IS NULL) OR
    (subject_id IS NULL AND activity_name IS NOT NULL)
  );
```

`subject_id` FK uses `ON DELETE RESTRICT` (not `SET NULL`) — MySQL 8.0 forbids combining `SET NULL` with a CHECK constraint on the same column (error 3823). The orphan-to-ad-hoc cascade is implemented in the use case layer (see `orphan-to-ad-hoc cascade` below) rather than via FK action.

## Orphan-to-ad-hoc cascade

Deleting a subject or semester no longer cascade-deletes its sessions. Instead, the use case nulls `subject_id` on every affected session and writes `activity_name` from the old subject name *before* the delete. From the user's POV, deletion preserves the time logged — it just demotes the rows to ad-hoc. The active semester cannot be deleted at all (UI block + server validation).

This is documented in `DeleteSubject` and `DeleteSemester` use cases. The `IStudySessionRepository.orphanBySubjectId(subjectId, activityName)` method is the single chokepoint.

## UI rules

- **Pill visibility:** the `ActiveSemesterPill` only renders when the user has 1+ semesters with one active. Fresh users see no pill; the dashboard layout is otherwise identical.
- **Ad-hoc running state:** when a session has no `subject_id`, the home tile shows the activity name as plain Cocoa Ink text — no color dot, no chip background. Per DESIGN.md, *absence of color* is the ad-hoc signal.
- **Subject form sheet:** when no semesters exist, the sheet expands inline to capture term name + dates alongside subject fields. Submission is one atomic flow: create the semester first, then the subject.

## Consequences

- The backend's `StartSession` use case accepts `{subjectId} XOR {activityName}` (Zod refine). `UpdateSession` honors the same invariant on edits.
- `GetAnalytics` excludes ad-hoc sessions from the subject totals map; the dashboard's `_SubjectTotalsList` adds an `"other"` aggregate row when `adHocSeconds > 0`.
- `SubjectsCubit` drops the legacy `SubjectsNoSemesters` state; the cubit is now bound to an explicit `loadForSemester(String?)` call driven by a shell-level `BlocListener<SemestersCubit>`.
- Future work — a backend-level `adHocSeconds` field on the analytics summary would let the mobile client drop its `ISessionRepository` dependency in `DashboardStatsCubit`. Acceptable layer-bend for v1 to avoid an API surface change.

Implementation plan: `docs/superpowers/plans/2026-05-24-warm-studygram-semester-adhoc.md`.

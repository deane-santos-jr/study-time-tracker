# Warm Studygram — Semester + Ad-hoc Activities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the foundational pivot from "semester is required" to "semester is optional via ad-hoc activity escape valve," ship the full semester management UI (manager screen, pill in app bar, create / edit / delete sheets), and rewire deletion to orphan-instead-of-cascade — all while keeping the studygram aesthetic intact.

**Architecture:** Backend keeps the Semester → Subject → Session hierarchy. The new escape valve is at the session level: `sessions.subject_id` becomes nullable and a new `sessions.activity_name` column lets sessions live without a subject. Subject and semester deletion become *hard* deletes that first orphan attached sessions (set `subject_id=NULL`, copy the deleted subject's name into `activity_name`) — no data loss. The active-semester pill is conditional UI chrome shown only when ≥1 semester exists. Mobile gets a new `SemestersCubit`, a new `/semesters` top-level route outside the StatefulShellRoute, an "+ something else" chip in the dashboard subject picker for ad-hoc entry, and inline-input ad-hoc mode in `SessionTile`.

**Tech Stack:** Backend — Express + TypeORM + MySQL 8.0 (CHECK constraints supported), Zod validation, Jest + supertest. Mobile — Flutter 3.41 + Dart 3.11, flutter_bloc + get_it + go_router, bloc_test + mocktail for cubit tests.

---

## Locked design decisions (from grilling sessions 1 & 2)

### Session 2 (foundational pivot)

- **Flexibility tweak, not positioning shift** — keep studygram voice, semester names, subject names; just make semester *optional from the user's perspective* by adding an ad-hoc escape valve at the session level.
- **Schema:** `sessions.subject_id` becomes nullable. New column `sessions.activity_name VARCHAR(100) NULL`. CHECK constraint: exactly one of (subject_id, activity_name) is non-null. Subjects keep their required semester FK (no change to `subjects.semester_id`).
- **Ad-hoc entry on dashboard:** `"+ something else"` chip pinned at the end of the subject picker row. Tap → inline text input replaces the subject-chip slot in `SessionTile` (autofocus, placeholder `"what are you doing?"`). Start enables when non-empty. Re-tap chip OR tap a subject chip exits ad-hoc mode. 100-char silent cap. No autocomplete in v1.
- **Ad-hoc running-state visual:** no marker, no color dot, plain Cocoa Ink text in the chip slot. Absence of color is the signal.
- **Active-semester pill in dashboard app bar title slot:** hidden when 0 semesters. When shown: cream chip (`surfaceContainer`), ~32px tall, `Radii.full`, lowercase Geist 14pt semibold ink label, no icon, no chevron. Tap routes to `/semesters` manager. Max width ~180px with ellipsis. Loading state: `"…"` placeholder, no tap target.
- **First-subject-with-no-semester flow:** inline two-section bottom sheet. Top section: subject fields. Bottom section (collapsed/expanded based on whether semesters exist): semester fields with framing line *"to organize subjects, group them into a term"*. Both submit as a single atomic transaction. Dates default to today + (today + 4 months). Cancel discards both drafts. No "make active" toggle in the inline section (first semester auto-activates).
- **Per-subject totals treatment of ad-hoc:** single `"other"` aggregate row at the bottom of `_SubjectTotalsList`, no color dot, hidden when 0 ad-hoc time in the period.
- **Subject / semester deletion:** orphan sessions to ad-hoc. Set `subject_id=NULL`, copy subject name into `activity_name`. No data loss on cascade. Cascade-preview sheet copy reads *"X sessions / Y hours preserved as ad-hoc."* No undo in v1.
- **Subjects screen pill integration:** pill replaces `"subjects"` Fraunces-italic title when ≥1 semester; falls back to Fraunces-italic title when 0 semesters.

### Session 2 (post-action UX)

- Toast on create: `"<name> added"` or `"<name> is now your active term"` (if first / auto-active). 2s.
- No toast on edit (in-place visual change is the confirmation).
- Toast on delete: `"X sessions preserved as ad-hoc"` (load-bearing copy when X > 0) or `"<name> removed"` (when X == 0). 3s on orphan case, 2s otherwise.
- Toast on activate: `"<name> is now active"`. 2s.
- No undo affordance in v1.

### Session 1 decisions inherited (unchanged)

- **#1** Dedicated `mobile/lib/src/presentation/modules/study/semesters/` module with own `SemestersCubit`.
- **#3** Pill scope: dashboard + subjects screens (not analytics, not profile).
- **#5** Card interactions on manager: tap to activate; overflow `…` icon for edit / delete menu.
- **#8** Create form is a bottom-sheet modal, ~85% height, drag handle. Reused for edit. "Make this active" toggle defaults on when 0 active exists.
- **#9** List order: active pinned top under `"active"` header; rest under `"past terms"` header sorted by `startDate desc`.
- **#10** Top-level `/semesters` route outside `StatefulShellRoute` — bottom nav hides during management.
- **#11** New endpoint `GET /semesters/:id/stats` returning `{ subjectCount, sessionCount, totalSeconds }`.
- **#12** `BlocListener<SemestersCubit, …>` at shell level calls `SubjectsCubit.loadForSemester(activeId)` when active changes.

### Session 1 decisions amended

- **#2** Pill in dashboard app bar title slot → conditional on ≥1 semester (hidden otherwise).
- **#6** Cascade-delete → orphan-to-ad-hoc. Cascade preview shows session/hour counts and "will be preserved" copy. Still blocks deletion of *active* semester (forces user to switch first).
- **#7** Empty-state pill copy "+ add semester" → removed. Dashboard with 0 semesters has no pill; discovery happens via the subject creation flow.

---

## File touch map

### Backend — create

- `backend/src/infrastructure/database/migrations/1700000000005-AddSessionActivityName.ts`
- `backend/src/application/use-cases/semester/GetSemesterStats.ts`
- `backend/src/__tests__/sessions/start-adhoc.test.ts`
- `backend/src/__tests__/semesters/stats.test.ts`
- `backend/src/__tests__/semesters/delete-cascade.test.ts`
- `backend/src/__tests__/subjects/delete-orphan.test.ts`

### Backend — modify

- `backend/src/domain/entities/StudySession.ts` — subjectId optional, semesterId optional, add activityName
- `backend/src/domain/repositories/IStudySessionRepository.ts` — add `orphanBySubjectId(subjectId, activityName)`, drop `findBySubjectId` semantic to "subjectId nullable"
- `backend/src/domain/repositories/ISubjectRepository.ts` — hard-delete signature unchanged but semantics change
- `backend/src/infrastructure/database/entities/StudySessionEntity.ts` — column changes
- `backend/src/infrastructure/database/repositories/StudySessionRepository.ts` — implement `orphanBySubjectId`
- `backend/src/infrastructure/database/repositories/SubjectRepository.ts` — hard delete via TypeORM `delete`; orphan sessions first via sessionRepository
- `backend/src/infrastructure/database/repositories/SemesterRepository.ts` — hard delete; cascade orphan via subjectRepository
- `backend/src/application/use-cases/session/StartSession.ts` — accept `{ subjectId } | { activityName }`
- `backend/src/application/use-cases/subject/DeleteSubject.ts` — orphan-then-delete
- `backend/src/application/use-cases/semester/DeleteSemester.ts` — block-if-active, cascade orphan
- `backend/src/application/use-cases/semester/UpdateSemester.ts` — (no behavior change; verify)
- `backend/src/presentation/controllers/SemesterController.ts` — add `getStats` action
- `backend/src/presentation/routes/semester.routes.ts` — add `GET /:id/stats`
- `backend/src/presentation/routes/session.routes.ts` — update validation: `subjectId XOR activityName`

### Mobile — create

- `mobile/lib/src/domain/models/semester/semester_stats.dart`
- `mobile/lib/src/presentation/modules/study/semesters/services/semesters_cubit.dart`
- `mobile/lib/src/presentation/modules/study/semesters/services/semesters_state.dart`
- `mobile/lib/src/presentation/modules/study/semesters/screens/semesters_screen.dart`
- `mobile/lib/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart`
- `mobile/lib/src/presentation/modules/study/semesters/widgets/semester_card.dart`
- `mobile/lib/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart`
- `mobile/lib/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart`
- `mobile/lib/src/presentation/modules/subjects/widgets/subject_form_sheet.dart`
- `mobile/test/semesters_cubit_test.dart`
- `mobile/test/subjects_cubit_test.dart`
- `mobile/test/active_semester_pill_test.dart` (optional widget test)

### Mobile — modify

- `mobile/lib/src/domain/models/session/study_session.dart` — subjectId nullable, add activityName
- `mobile/lib/src/domain/models/session/session_payload.dart` — `StartSessionPayload` supports activityName
- `mobile/lib/src/domain/models/semester/semester_payload.dart` — add `SemesterUpdatePayload`
- `mobile/lib/src/domain/repositories/semester_repository_intf.dart` — add update/delete/getStats
- `mobile/lib/src/data/repositories/semester_repository.dart` — implement update/delete/getStats
- `mobile/lib/src/presentation/modules/study/dashboard/services/active_session_cubit.dart` — add `startAdHoc`
- `mobile/lib/src/presentation/modules/subjects/services/subjects_cubit.dart` — remove `SubjectsNoSemesters` state; add `loadForSemester(String? semesterId)`
- `mobile/lib/src/presentation/modules/subjects/services/subjects_state.dart` — drop `SubjectsNoSemesters`
- `mobile/lib/src/presentation/modules/study/dashboard/widgets/subject_selector.dart` — add `"+ something else"` chip
- `mobile/lib/src/presentation/modules/study/dashboard/widgets/session_tile.dart` — ad-hoc input mode + no-marker running state
- `mobile/lib/src/presentation/modules/study/dashboard/screens/dashboard_screen.dart` — pill in app bar (conditional), drop `_NoSubjectsBody` no-semester variant, "other" aggregate row in `_SubjectTotalsList`, ad-hoc start wiring
- `mobile/lib/src/presentation/modules/subjects/screens/subjects_list_screen.dart` — pill in title slot when ≥1 semester; drop `_NoSemesterBody` (replaced by sheet flow)
- `mobile/lib/src/presentation/modules/subjects/screens/subject_form_screen.dart` — likely deprecated by `subject_form_sheet.dart`; remove or keep as redirect to sheet
- `mobile/lib/src/presentation/modules/study/shell/screens/study_shell_screen.dart` — `BlocListener` wiring for active-semester change
- `mobile/lib/core/utils/router.dart` — add top-level `/semesters` route outside the StatefulShellRoute
- `mobile/lib/core/utils/injection_container.dart` — register `SemestersCubit` under new `// MARK: semesters-…-start/end` block
- `mobile/lib/main.dart` — register `SemestersCubit` in `MultiBlocProvider`

---

## Phase 1 — Backend: schema migration + domain entity

### Task 1: Add migration for `sessions.subject_id` nullable + `activity_name` column

**Files:**
- Create: `backend/src/infrastructure/database/migrations/1700000000005-AddSessionActivityName.ts`

This migration drops the `NOT NULL` constraint on `sessions.subject_id`, adds a nullable `activity_name VARCHAR(100)`, and adds a CHECK constraint enforcing exactly one of the two columns is non-null on every row. MySQL 8.0.16+ supports CHECK constraints natively.

- [ ] **Step 1: Write the migration**

```typescript
import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSessionActivityName1700000000005 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // First drop the foreign key — TypeORM created it implicitly via the
    // @ManyToOne decorator on StudySessionEntity. Name lookup via
    // information_schema so we don't have to hard-code the auto-generated
    // constraint name.
    const fkRows: Array<{ CONSTRAINT_NAME: string }> = await queryRunner.query(
      `SELECT CONSTRAINT_NAME
       FROM information_schema.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = 'study_sessions'
         AND COLUMN_NAME = 'subject_id'
         AND REFERENCED_TABLE_NAME = 'subjects'`
    );
    for (const row of fkRows) {
      await queryRunner.query(
        `ALTER TABLE study_sessions DROP FOREIGN KEY \`${row.CONSTRAINT_NAME}\``
      );
    }

    // Make subject_id nullable
    await queryRunner.query(`
      ALTER TABLE study_sessions
      MODIFY COLUMN subject_id VARCHAR(36) NULL
    `);

    // Make semester_id nullable too — sessions orphaned from a deleted
    // semester (via cascade) need somewhere to land
    await queryRunner.query(`
      ALTER TABLE study_sessions
      MODIFY COLUMN semester_id VARCHAR(36) NULL
    `);

    // Add activity_name
    await queryRunner.query(`
      ALTER TABLE study_sessions
      ADD COLUMN activity_name VARCHAR(100) NULL AFTER subject_id
    `);

    // Re-add the FK with ON DELETE SET NULL — when a subject is hard-deleted
    // and the orphan-flow ran in the use case to copy the name first, the FK
    // also defensively nulls subject_id if the use case is bypassed.
    await queryRunner.query(`
      ALTER TABLE study_sessions
      ADD CONSTRAINT fk_sessions_subject
      FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE SET NULL
    `);

    // CHECK constraint: exactly one of subject_id or activity_name is set
    await queryRunner.query(`
      ALTER TABLE study_sessions
      ADD CONSTRAINT chk_sessions_subject_or_activity
      CHECK (
        (subject_id IS NOT NULL AND activity_name IS NULL)
        OR (subject_id IS NULL AND activity_name IS NOT NULL)
      )
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE study_sessions
      DROP CONSTRAINT chk_sessions_subject_or_activity
    `);

    // Drop the SET NULL FK
    const fkRows: Array<{ CONSTRAINT_NAME: string }> = await queryRunner.query(
      `SELECT CONSTRAINT_NAME
       FROM information_schema.KEY_COLUMN_USAGE
       WHERE TABLE_SCHEMA = DATABASE()
         AND TABLE_NAME = 'study_sessions'
         AND COLUMN_NAME = 'subject_id'
         AND REFERENCED_TABLE_NAME = 'subjects'`
    );
    for (const row of fkRows) {
      await queryRunner.query(
        `ALTER TABLE study_sessions DROP FOREIGN KEY \`${row.CONSTRAINT_NAME}\``
      );
    }

    await queryRunner.query(`
      ALTER TABLE study_sessions DROP COLUMN activity_name
    `);

    // Reverse the nullable change — fill any NULL rows (shouldn't exist by
    // CHECK constraint we just dropped) with an arbitrary subject before
    // re-applying NOT NULL.
    await queryRunner.query(`
      DELETE FROM study_sessions WHERE subject_id IS NULL OR semester_id IS NULL
    `);
    await queryRunner.query(`
      ALTER TABLE study_sessions
      MODIFY COLUMN subject_id VARCHAR(36) NOT NULL
    `);
    await queryRunner.query(`
      ALTER TABLE study_sessions
      MODIFY COLUMN semester_id VARCHAR(36) NOT NULL
    `);
    await queryRunner.query(`
      ALTER TABLE study_sessions
      ADD CONSTRAINT fk_sessions_subject
      FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
    `);
  }
}
```

- [ ] **Step 2: Run migration against local dev database**

Run from `backend/`: `npm run migration:run`
Expected: command exits 0; new column `activity_name` appears in MySQL; constraint `chk_sessions_subject_or_activity` exists.

To verify:
```bash
docker compose exec mysql mysql -u root -p<password> -e \
  "SHOW CREATE TABLE timetracker.study_sessions\G" | grep -E "(activity_name|chk_sessions|subject_id)"
```
Expected output includes the new column, the CHECK constraint, and `subject_id` as `varchar(36) DEFAULT NULL`.

- [ ] **Step 3: Test rollback works**

Run: `npm run migration:revert`
Then: `npm run migration:run`
Both should exit 0. This protects future rollback drills.

- [ ] **Step 4: Commit**

```bash
git add backend/src/infrastructure/database/migrations/1700000000005-AddSessionActivityName.ts
git commit -m "feat(db): make sessions.subject_id nullable and add activity_name

Add migration to make subject_id and semester_id nullable on study_sessions
and introduce activity_name VARCHAR(100). CHECK constraint enforces exactly
one of (subject_id, activity_name) per row. Foreign key changed to
ON DELETE SET NULL so orphan-on-delete flow can preserve session rows."
```

### Task 2: Update `StudySession` domain entity for nullable subject + activity name

**Files:**
- Modify: `backend/src/domain/entities/StudySession.ts`

The domain entity needs to accept `null` for `subjectId` and `semesterId`, and gain an `activityName` field. The `create` factory needs an "ad-hoc" variant.

- [ ] **Step 1: Replace the entity contents**

```typescript
import { Break } from './Break';

export enum SessionStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
}

export class StudySession {
  constructor(
    public readonly id: string,
    public readonly userId: string,
    public subjectId: string | null,
    public semesterId: string | null,
    public activityName: string | null,
    public readonly startTime: Date,
    public endTime: Date | undefined,
    public pausedAt: Date | undefined,
    public status: SessionStatus,
    public totalDuration: number | undefined,
    public effectiveStudyTime: number | undefined,
    public breakCount: number,
    public accumulatedPauseTime: number,
    public readonly createdAt: Date,
    public updatedAt: Date
  ) {
    // Invariant: exactly one of (subjectId, activityName) is non-null.
    const hasSubject = subjectId !== null;
    const hasActivity = activityName !== null;
    if (hasSubject === hasActivity) {
      throw new Error(
        'StudySession must have exactly one of subjectId or activityName'
      );
    }
  }

  pause(): void {
    if (this.status !== SessionStatus.ACTIVE) {
      throw new Error('Can only pause an active session');
    }
    this.status = SessionStatus.PAUSED;
    this.pausedAt = new Date();
    this.updatedAt = new Date();
  }

  resume(): void {
    if (this.status !== SessionStatus.PAUSED) {
      throw new Error('Can only resume a paused session');
    }
    this.status = SessionStatus.ACTIVE;
    this.pausedAt = undefined;
    this.updatedAt = new Date();
  }

  stop(totalBreakTimeInSeconds: number = 0, totalPauseTimeInSeconds: number = 0): void {
    if (this.status === SessionStatus.COMPLETED) {
      throw new Error('Session already completed');
    }
    this.endTime = new Date();
    this.status = SessionStatus.COMPLETED;
    this.totalDuration = Math.floor((this.endTime.getTime() - this.startTime.getTime()) / 1000);
    this.effectiveStudyTime = this.totalDuration - totalBreakTimeInSeconds - totalPauseTimeInSeconds;
    this.updatedAt = new Date();
  }

  getCurrentDuration(): number {
    const endTime = this.endTime || new Date();
    return Math.floor((endTime.getTime() - this.startTime.getTime()) / 1000);
  }

  isActive(): boolean {
    return this.status === SessionStatus.ACTIVE;
  }

  belongsToUser(userId: string): boolean {
    return this.userId === userId;
  }

  isAdHoc(): boolean {
    return this.subjectId === null;
  }

  /**
   * Convert a subject-attached session to ad-hoc. Used when a subject is
   * deleted — the session keeps its history but the subject identity becomes
   * a free-text activity name.
   */
  orphanToAdHoc(activityName: string): void {
    if (this.subjectId === null) {
      throw new Error('Session is already ad-hoc');
    }
    this.subjectId = null;
    this.semesterId = null;
    this.activityName = activityName;
    this.updatedAt = new Date();
  }

  static createForSubject(
    id: string,
    userId: string,
    subjectId: string,
    semesterId: string
  ): StudySession {
    return new StudySession(
      id,
      userId,
      subjectId,
      semesterId,
      null,
      new Date(),
      undefined,
      undefined,
      SessionStatus.ACTIVE,
      undefined,
      undefined,
      0,
      0,
      new Date(),
      new Date()
    );
  }

  static createAdHoc(
    id: string,
    userId: string,
    activityName: string
  ): StudySession {
    return new StudySession(
      id,
      userId,
      null,
      null,
      activityName,
      new Date(),
      undefined,
      undefined,
      SessionStatus.ACTIVE,
      undefined,
      undefined,
      0,
      0,
      new Date(),
      new Date()
    );
  }
}
```

- [ ] **Step 2: Run typecheck**

Run from `backend/`: `npm run build`
Expected: many errors in other files (repository, use cases, controller) referencing the old positional constructor signature and removed `create` method. That's fine — we'll fix them in subsequent tasks. Confirm the entity file itself compiles in isolation by checking the error list shows other files, not this one.

- [ ] **Step 3: Commit**

```bash
git add backend/src/domain/entities/StudySession.ts
git commit -m "feat(domain): make StudySession.subjectId nullable and add activityName

Adds invariant that exactly one of subjectId or activityName must be set.
Splits the create factory into createForSubject and createAdHoc.
Adds orphanToAdHoc method for the cascade-delete flow.

Other files referencing StudySession will fail to compile until updated
in subsequent commits — this is the schema-then-entity step in the
broader pivot."
```

### Task 3: Update TypeORM entity for the new columns

**Files:**
- Modify: `backend/src/infrastructure/database/entities/StudySessionEntity.ts`

- [ ] **Step 1: Replace the entity file**

```typescript
import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { UserEntity } from './UserEntity';
import { SubjectEntity } from './SubjectEntity';
import { BreakEntity } from './BreakEntity';

export enum SessionStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
}

@Entity('study_sessions')
export class StudySessionEntity {
  @PrimaryColumn('varchar', { length: 36 })
  id!: string;

  @Column({ name: 'user_id' })
  userId!: string;

  @Column({ name: 'subject_id', type: 'varchar', length: 36, nullable: true })
  subjectId!: string | null;

  @Column({ name: 'activity_name', type: 'varchar', length: 100, nullable: true })
  activityName!: string | null;

  @Column({ name: 'semester_id', type: 'varchar', length: 36, nullable: true })
  semesterId!: string | null;

  @Column({ name: 'start_time', type: 'datetime' })
  startTime!: Date;

  @Column({ name: 'end_time', type: 'datetime', nullable: true })
  endTime?: Date;

  @Column({ name: 'paused_at', type: 'datetime', nullable: true })
  pausedAt?: Date;

  @Column({ type: 'enum', enum: SessionStatus, default: SessionStatus.ACTIVE })
  status!: SessionStatus;

  @Column({ name: 'total_duration', type: 'int', nullable: true })
  totalDuration?: number;

  @Column({ name: 'effective_study_time', type: 'int', nullable: true })
  effectiveStudyTime?: number;

  @Column({ name: 'break_count', type: 'int', default: 0 })
  breakCount!: number;

  @Column({ name: 'accumulated_pause_time', type: 'int', default: 0 })
  accumulatedPauseTime!: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => UserEntity, (user) => user.sessions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @ManyToOne(() => SubjectEntity, (subject) => subject.sessions, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'subject_id' })
  subject!: SubjectEntity | null;

  @OneToMany(() => BreakEntity, (breakEntity) => breakEntity.session)
  breaks?: BreakEntity[];
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/infrastructure/database/entities/StudySessionEntity.ts
git commit -m "feat(db): update StudySessionEntity for nullable subject_id and activity_name

ManyToOne to Subject becomes nullable with ON DELETE SET NULL (matching the
migration). Adds activity_name column."
```

---

## Phase 2 — Backend: repositories (orphan + hard-delete logic)

### Task 4: Extend `IStudySessionRepository` with orphan operation

**Files:**
- Modify: `backend/src/domain/repositories/IStudySessionRepository.ts`

- [ ] **Step 1: Replace the interface**

```typescript
import { StudySession } from '../entities/StudySession';

export interface IStudySessionRepository {
  create(session: StudySession): Promise<StudySession>;
  findById(id: string): Promise<StudySession | null>;
  findByUserId(userId: string): Promise<StudySession[]>;
  findActiveByUserId(userId: string): Promise<StudySession | null>;
  findBySubjectId(subjectId: string): Promise<StudySession[]>;
  findBySemesterId(semesterId: string): Promise<StudySession[]>;
  update(session: StudySession): Promise<StudySession>;
  delete(id: string): Promise<void>;

  /**
   * Convert every session belonging to the given subject into an ad-hoc
   * session. Used by SubjectRepository.delete (and transitively by
   * SemesterRepository.delete) to preserve history when a subject is removed.
   * Sets subject_id=NULL, semester_id=NULL, activity_name=<provided>, and
   * returns the number of rows affected.
   */
  orphanBySubjectId(subjectId: string, activityName: string): Promise<number>;
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/domain/repositories/IStudySessionRepository.ts
git commit -m "feat(domain): add IStudySessionRepository.orphanBySubjectId"
```

### Task 5: Implement `StudySessionRepository` for nullable subject + orphan op

**Files:**
- Modify: `backend/src/infrastructure/database/repositories/StudySessionRepository.ts`

- [ ] **Step 1: Replace the repository implementation**

```typescript
import { Repository, IsNull, Not } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { StudySessionEntity } from '../entities/StudySessionEntity';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { StudySession, SessionStatus } from '../../../domain/entities/StudySession';

export class StudySessionRepository implements IStudySessionRepository {
  private repository: Repository<StudySessionEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(StudySessionEntity);
  }

  async create(session: StudySession): Promise<StudySession> {
    const sessionEntity = this.repository.create({
      id: session.id,
      userId: session.userId,
      subjectId: session.subjectId,
      semesterId: session.semesterId,
      activityName: session.activityName,
      startTime: session.startTime,
      endTime: session.endTime,
      pausedAt: session.pausedAt,
      status: session.status,
      totalDuration: session.totalDuration,
      effectiveStudyTime: session.effectiveStudyTime,
      breakCount: session.breakCount,
      accumulatedPauseTime: session.accumulatedPauseTime,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    });

    const saved = await this.repository.save(sessionEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<StudySession | null> {
    const sessionEntity = await this.repository.findOne({ where: { id } });
    return sessionEntity ? this.toDomain(sessionEntity) : null;
  }

  async findByUserId(userId: string): Promise<StudySession[]> {
    const sessionEntities = await this.repository.find({
      where: { userId },
      order: { startTime: 'DESC' },
    });
    return sessionEntities.map((entity) => this.toDomain(entity));
  }

  async findActiveByUserId(userId: string): Promise<StudySession | null> {
    const sessionEntity = await this.repository.findOne({
      where: [
        { userId, status: SessionStatus.ACTIVE },
        { userId, status: SessionStatus.PAUSED },
      ],
      order: { startTime: 'DESC' },
    });
    return sessionEntity ? this.toDomain(sessionEntity) : null;
  }

  async findBySubjectId(subjectId: string): Promise<StudySession[]> {
    const sessionEntities = await this.repository.find({
      where: { subjectId },
      order: { startTime: 'DESC' },
    });
    return sessionEntities.map((entity) => this.toDomain(entity));
  }

  async findBySemesterId(semesterId: string): Promise<StudySession[]> {
    const sessionEntities = await this.repository.find({
      where: { semesterId },
      order: { startTime: 'DESC' },
    });
    return sessionEntities.map((entity) => this.toDomain(entity));
  }

  async update(session: StudySession): Promise<StudySession> {
    await this.repository.update(session.id, {
      subjectId: session.subjectId,
      semesterId: session.semesterId,
      activityName: session.activityName,
      endTime: session.endTime,
      pausedAt: session.pausedAt,
      status: session.status,
      totalDuration: session.totalDuration,
      effectiveStudyTime: session.effectiveStudyTime,
      breakCount: session.breakCount,
      accumulatedPauseTime: session.accumulatedPauseTime,
      updatedAt: new Date(),
    });

    const updated = await this.repository.findOne({ where: { id: session.id } });
    if (!updated) {
      throw new Error('Session not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  async orphanBySubjectId(subjectId: string, activityName: string): Promise<number> {
    const result = await this.repository
      .createQueryBuilder()
      .update(StudySessionEntity)
      .set({
        subjectId: null,
        semesterId: null,
        activityName,
        updatedAt: () => 'NOW()',
      })
      .where('subject_id = :subjectId', { subjectId })
      .execute();

    return result.affected ?? 0;
  }

  private toDomain(entity: StudySessionEntity): StudySession {
    return new StudySession(
      entity.id,
      entity.userId,
      entity.subjectId,
      entity.semesterId,
      entity.activityName,
      entity.startTime,
      entity.endTime,
      entity.pausedAt,
      entity.status as SessionStatus,
      entity.totalDuration,
      entity.effectiveStudyTime,
      entity.breakCount,
      entity.accumulatedPauseTime || 0,
      entity.createdAt,
      entity.updatedAt
    );
  }
}
```

- [ ] **Step 2: Run typecheck**

Run from `backend/`: `npm run build`
Expected: this file now compiles. Other call sites still fail.

- [ ] **Step 3: Commit**

```bash
git add backend/src/infrastructure/database/repositories/StudySessionRepository.ts
git commit -m "feat(db): implement nullable subject_id support and orphanBySubjectId

The orphan operation is a bulk UPDATE so it stays cheap even for subjects
with thousands of sessions. NOW() is passed as a TypeORM expression to let
MySQL set the timestamp server-side."
```

### Task 6: Update `SubjectRepository.delete` to hard-delete (was soft-delete)

**Files:**
- Modify: `backend/src/infrastructure/database/repositories/SubjectRepository.ts`

The current behavior soft-deletes by setting `isActive=false`. Under the new model we want hard delete — the use case (`DeleteSubject`) handles the orphan flow first, then calls this. Hard delete is what allows the FK cascade (`ON DELETE SET NULL`) to fire if the orphan flow is somehow bypassed.

- [ ] **Step 1: Replace the `delete` method**

Find this in `backend/src/infrastructure/database/repositories/SubjectRepository.ts`:

```typescript
async delete(id: string): Promise<void> {
  // Soft delete by setting isActive to false
  await this.repository.update(id, { isActive: false, updatedAt: new Date() });
}
```

Replace with:

```typescript
async delete(id: string): Promise<void> {
  await this.repository.delete(id);
}
```

- [ ] **Step 2: Run typecheck**

Run from `backend/`: `npm run build`
Expected: this file compiles. Other call sites still fail.

- [ ] **Step 3: Commit**

```bash
git add backend/src/infrastructure/database/repositories/SubjectRepository.ts
git commit -m "feat(db): change SubjectRepository.delete to hard delete

The orphan-to-ad-hoc cascade is now handled by the DeleteSubject use case
before this method is called. Hard delete is what allows the FK's
ON DELETE SET NULL to fire defensively if the orphan flow is bypassed."
```

### Task 7: Update `SemesterRepository.delete` to hard-delete

**Files:**
- Modify: `backend/src/infrastructure/database/repositories/SemesterRepository.ts`

Same pattern as subject repository. The cascade-orphan flow is handled in the use case.

- [ ] **Step 1: Replace the `delete` method**

Find:

```typescript
async delete(id: string): Promise<void> {
  // Soft delete
  await this.repository.update(id, { isActive: false, updatedAt: new Date() });
}
```

Replace with:

```typescript
async delete(id: string): Promise<void> {
  await this.repository.delete(id);
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/infrastructure/database/repositories/SemesterRepository.ts
git commit -m "feat(db): change SemesterRepository.delete to hard delete"
```

---

## Phase 3 — Backend: use cases (ad-hoc start, orphan flows, stats)

### Task 8: Update `StartSession` use case to accept ad-hoc

**Files:**
- Modify: `backend/src/application/use-cases/session/StartSession.ts`

The DTO grows to `{ subjectId?: string; activityName?: string }`. The use case validates exactly one is provided; for `activityName` it trims and length-checks; for `subjectId` it loads the subject and derives `semesterId` as before.

- [ ] **Step 1: Replace the use case**

```typescript
import { v4 as uuidv4 } from 'uuid';
import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { ValidationError, NotFoundError, ConflictError } from '../../../shared/errors/AppError';

export interface StartSessionDTO {
  subjectId?: string;
  activityName?: string;
}

export class StartSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private subjectRepository: ISubjectRepository
  ) {}

  async execute(userId: string, dto: StartSessionDTO): Promise<StudySession & { accumulatedBreakTime?: number; hasActiveBreak?: boolean; accumulatedPauseTime?: number }> {
    const hasSubject = !!dto.subjectId;
    const hasActivity = !!dto.activityName?.trim();
    if (hasSubject === hasActivity) {
      throw new ValidationError(
        'Provide exactly one of subjectId or activityName'
      );
    }

    const activeSession = await this.sessionRepository.findActiveByUserId(userId);
    if (activeSession) {
      throw new ConflictError('You already have an active session. Please stop it before starting a new one.');
    }

    let session: StudySession;
    if (hasSubject) {
      const subject = await this.subjectRepository.findById(dto.subjectId!);
      if (!subject) {
        throw new NotFoundError('Subject not found');
      }
      if (subject.userId !== userId) {
        throw new ValidationError('Subject does not belong to you');
      }
      session = StudySession.createForSubject(
        uuidv4(),
        userId,
        dto.subjectId!,
        subject.semesterId
      );
    } else {
      const trimmed = dto.activityName!.trim();
      if (trimmed.length === 0 || trimmed.length > 100) {
        throw new ValidationError(
          'activityName must be 1-100 characters'
        );
      }
      session = StudySession.createAdHoc(uuidv4(), userId, trimmed);
    }

    const createdSession = await this.sessionRepository.create(session);
    return { ...createdSession, accumulatedBreakTime: 0, hasActiveBreak: false, accumulatedPauseTime: 0 };
  }
}
```

- [ ] **Step 2: Update the session route validation schema**

Modify `backend/src/presentation/routes/session.routes.ts`. Replace the `startSessionSchema` definition:

```typescript
const startSessionSchema = z.object({
  subjectId: z.string().uuid('Invalid subject ID').optional(),
  semesterId: z.string().uuid().optional(),
  activityName: z.string().min(1).max(100).optional(),
}).refine(
  (data) => {
    const hasSubject = !!data.subjectId;
    const hasActivity = !!data.activityName?.trim();
    return hasSubject !== hasActivity;
  },
  { message: 'Provide exactly one of subjectId or activityName' }
);
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/application/use-cases/session/StartSession.ts \
        backend/src/presentation/routes/session.routes.ts
git commit -m "feat(api): StartSession accepts subjectId XOR activityName

Adds ad-hoc session start path. Zod refines the schema so exactly one of
subjectId/activityName is required (semesterId is now derived from the
subject when subjectId is given; it's never required from the client)."
```

### Task 9: Rewire `DeleteSubject` use case for orphan-then-delete

**Files:**
- Modify: `backend/src/application/use-cases/subject/DeleteSubject.ts`

- [ ] **Step 1: Replace the use case**

```typescript
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export interface DeleteSubjectResult {
  orphanedSessionCount: number;
}

export class DeleteSubject {
  constructor(
    private subjectRepository: ISubjectRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, subjectId: string): Promise<DeleteSubjectResult> {
    const subject = await this.subjectRepository.findById(subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }

    if (subject.userId !== userId) {
      throw new ForbiddenError('You do not have permission to delete this subject');
    }

    // Orphan sessions first — copy the subject's name into activity_name so
    // the history is preserved as ad-hoc records.
    const orphanedSessionCount = await this.sessionRepository.orphanBySubjectId(
      subjectId,
      subject.name
    );

    await this.subjectRepository.delete(subjectId);

    return { orphanedSessionCount };
  }
}
```

- [ ] **Step 2: Update the controller to pass the session repository and return the count**

Modify `backend/src/presentation/controllers/SubjectController.ts`. Find the existing `delete` controller method (which constructs `DeleteSubject` with only `subjectRepository`) and update it. If the file doesn't yet import `StudySessionRepository`, add the import.

Replace the `delete` method body with:

```typescript
async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const deleteSubject = new DeleteSubject(
      this.subjectRepository,
      this.sessionRepository
    );
    const userId = req.userId!;
    const { id } = req.params;

    const result = await deleteSubject.execute(userId, id);

    res.status(200).json({
      success: true,
      message: 'Subject deleted successfully',
      data: { orphanedSessionCount: result.orphanedSessionCount },
    });
  } catch (error) {
    next(error);
  }
}
```

Also ensure `this.sessionRepository` is instantiated in the constructor:

```typescript
constructor() {
  this.subjectRepository = new SubjectRepository();
  this.sessionRepository = new StudySessionRepository();
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/application/use-cases/subject/DeleteSubject.ts \
        backend/src/presentation/controllers/SubjectController.ts
git commit -m "feat(api): DeleteSubject orphans sessions to ad-hoc before deleting

Sessions become activity-named records (activity_name = subject.name) with
NULL subject_id/semester_id. Response payload includes orphanedSessionCount
so the mobile delete sheet can render 'X sessions preserved as ad-hoc'."
```

### Task 10: Rewire `DeleteSemester` for cascade-orphan + active-block

**Files:**
- Modify: `backend/src/application/use-cases/semester/DeleteSemester.ts`

The semester delete blocks if the semester is currently active (forces user to switch first). Otherwise it cascade-orphans: for every subject in the semester, orphan its sessions, then delete the subject, then delete the semester.

- [ ] **Step 1: Replace the use case**

```typescript
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import {
  NotFoundError,
  ForbiddenError,
  ValidationError,
} from '../../../shared/errors/AppError';

export interface DeleteSemesterResult {
  orphanedSubjectCount: number;
  orphanedSessionCount: number;
}

export class DeleteSemester {
  constructor(
    private semesterRepository: ISemesterRepository,
    private subjectRepository: ISubjectRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, semesterId: string): Promise<DeleteSemesterResult> {
    const semester = await this.semesterRepository.findById(semesterId);

    if (!semester) {
      throw new NotFoundError('Semester not found');
    }

    if (!semester.belongsToUser(userId)) {
      throw new ForbiddenError('You do not have permission to delete this semester');
    }

    if (semester.isActive) {
      throw new ValidationError(
        'Cannot delete the active semester. Switch active first.'
      );
    }

    // Find all subjects belonging to this semester.
    const allSubjects = await this.subjectRepository.findByUserId(userId);
    const subjectsInSemester = allSubjects.filter(
      (s) => s.semesterId === semesterId
    );

    // Cascade orphan: for each subject, orphan its sessions then delete it.
    let totalOrphanedSessions = 0;
    for (const subject of subjectsInSemester) {
      const orphanedCount = await this.sessionRepository.orphanBySubjectId(
        subject.id,
        subject.name
      );
      totalOrphanedSessions += orphanedCount;
      await this.subjectRepository.delete(subject.id);
    }

    await this.semesterRepository.delete(semesterId);

    return {
      orphanedSubjectCount: subjectsInSemester.length,
      orphanedSessionCount: totalOrphanedSessions,
    };
  }
}
```

- [ ] **Step 2: Update the controller to pass the extra repositories and return the counts**

Modify `backend/src/presentation/controllers/SemesterController.ts`. Add the new repositories to the constructor and update the `delete` method body. Replace the existing constructor + delete method:

```typescript
import { SubjectRepository } from '../../infrastructure/database/repositories/SubjectRepository';
import { StudySessionRepository } from '../../infrastructure/database/repositories/StudySessionRepository';

export class SemesterController {
  private semesterRepository: SemesterRepository;
  private subjectRepository: SubjectRepository;
  private sessionRepository: StudySessionRepository;

  constructor() {
    this.semesterRepository = new SemesterRepository();
    this.subjectRepository = new SubjectRepository();
    this.sessionRepository = new StudySessionRepository();
  }

  // ... keep existing create, getAll, getActive, update methods ...

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const deleteSemester = new DeleteSemester(
        this.semesterRepository,
        this.subjectRepository,
        this.sessionRepository
      );
      const userId = req.userId!;
      const { id } = req.params;

      const result = await deleteSemester.execute(userId, id);

      res.status(200).json({
        success: true,
        message: 'Semester deleted successfully',
        data: {
          orphanedSubjectCount: result.orphanedSubjectCount,
          orphanedSessionCount: result.orphanedSessionCount,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/application/use-cases/semester/DeleteSemester.ts \
        backend/src/presentation/controllers/SemesterController.ts
git commit -m "feat(api): DeleteSemester blocks if active, otherwise cascade-orphans

Active-semester deletion returns 400 (the mobile delete sheet enforces
this UX rule too, but the server must enforce it independently). Non-active
deletion: each subject's sessions become ad-hoc, then subjects are deleted,
then the semester is deleted. Response payload includes the counts so the
delete sheet can render orphan-preservation copy."
```

### Task 11: Add `GetSemesterStats` use case

**Files:**
- Create: `backend/src/application/use-cases/semester/GetSemesterStats.ts`

Returns `{ subjectCount, sessionCount, totalSeconds }` for a given semester. Used by the mobile delete-preview sheet and the per-card semester stats display.

- [ ] **Step 1: Write the use case**

```typescript
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export interface SemesterStats {
  subjectCount: number;
  sessionCount: number;
  totalSeconds: number;
}

export class GetSemesterStats {
  constructor(
    private semesterRepository: ISemesterRepository,
    private subjectRepository: ISubjectRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, semesterId: string): Promise<SemesterStats> {
    const semester = await this.semesterRepository.findById(semesterId);
    if (!semester) {
      throw new NotFoundError('Semester not found');
    }
    if (!semester.belongsToUser(userId)) {
      throw new ForbiddenError(
        'You do not have permission to view this semester'
      );
    }

    const allSubjects = await this.subjectRepository.findByUserId(userId);
    const subjectsInSemester = allSubjects.filter(
      (s) => s.semesterId === semesterId
    );

    let sessionCount = 0;
    let totalSeconds = 0;
    for (const subject of subjectsInSemester) {
      const sessions = await this.sessionRepository.findBySubjectId(subject.id);
      for (const session of sessions) {
        if (session.status === 'COMPLETED') {
          sessionCount += 1;
          totalSeconds += session.effectiveStudyTime ?? 0;
        }
      }
    }

    return { subjectCount: subjectsInSemester.length, sessionCount, totalSeconds };
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add backend/src/application/use-cases/semester/GetSemesterStats.ts
git commit -m "feat(api): add GetSemesterStats use case"
```

### Task 12: Wire `GET /semesters/:id/stats` endpoint

**Files:**
- Modify: `backend/src/presentation/controllers/SemesterController.ts`
- Modify: `backend/src/presentation/routes/semester.routes.ts`

- [ ] **Step 1: Add the controller method**

Add this import:

```typescript
import { GetSemesterStats } from '../../application/use-cases/semester/GetSemesterStats';
```

Then add this method to `SemesterController`:

```typescript
async getStats(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const getStats = new GetSemesterStats(
      this.semesterRepository,
      this.subjectRepository,
      this.sessionRepository
    );
    const userId = req.userId!;
    const { id } = req.params;

    const stats = await getStats.execute(userId, id);

    res.status(200).json({
      success: true,
      message: 'Semester stats retrieved successfully',
      data: stats,
    });
  } catch (error) {
    next(error);
  }
}
```

- [ ] **Step 2: Add the route**

Modify `backend/src/presentation/routes/semester.routes.ts`. Add this line after the existing `GET /active` route:

```typescript
router.get('/:id/stats', semesterController.getStats.bind(semesterController));
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/presentation/controllers/SemesterController.ts \
        backend/src/presentation/routes/semester.routes.ts
git commit -m "feat(api): expose GET /semesters/:id/stats"
```

---

## Phase 4 — Backend: integration tests via supertest

The backend has no existing test suite, but it has `jest` + `supertest` installed and a `npm test` script. We add a focused set of integration tests that spin up the Express app, hit the new endpoints, and assert behavior. Tests share a helper that creates a test user + auth token via the real `/auth/register` + `/auth/login` flow so we don't have to mock JWT.

### Task 13: Add test infrastructure (app bootstrap + auth helper)

**Files:**
- Create: `backend/src/__tests__/helpers/testApp.ts`
- Create: `backend/src/__tests__/helpers/auth.ts`

- [ ] **Step 1: Write the test app bootstrap**

```typescript
// backend/src/__tests__/helpers/testApp.ts
import 'reflect-metadata';
import express, { Application } from 'express';
import { AppDataSource } from '../../infrastructure/config/database.config';
import authRoutes from '../../presentation/routes/auth.routes';
import semesterRoutes from '../../presentation/routes/semester.routes';
import subjectRoutes from '../../presentation/routes/subject.routes';
import sessionRoutes from '../../presentation/routes/session.routes';
import { errorHandler } from '../../presentation/middlewares/errorHandler';

let app: Application | null = null;

export async function getTestApp(): Promise<Application> {
  if (app) return app;
  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }
  const instance = express();
  instance.use(express.json());
  instance.use('/api/v1/auth', authRoutes);
  instance.use('/api/v1/semesters', semesterRoutes);
  instance.use('/api/v1/subjects', subjectRoutes);
  instance.use('/api/v1/sessions', sessionRoutes);
  instance.use(errorHandler);
  app = instance;
  return app;
}

export async function closeTestApp(): Promise<void> {
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
  }
  app = null;
}
```

- [ ] **Step 2: Write the auth helper**

```typescript
// backend/src/__tests__/helpers/auth.ts
import request from 'supertest';
import { Application } from 'express';

export async function registerAndLogin(
  app: Application,
  prefix = 't'
): Promise<{ userId: string; token: string }> {
  const suffix = `${prefix}${Date.now()}${Math.floor(Math.random() * 1000)}`;
  const email = `${suffix}@test.local`;
  const password = 'Password123!';

  const reg = await request(app)
    .post('/api/v1/auth/register')
    .send({ email, password, name: `User ${suffix}` });

  if (reg.status !== 201) {
    throw new Error(`Register failed: ${reg.status} ${JSON.stringify(reg.body)}`);
  }

  const login = await request(app)
    .post('/api/v1/auth/login')
    .send({ email, password });

  if (login.status !== 200) {
    throw new Error(`Login failed: ${login.status} ${JSON.stringify(login.body)}`);
  }

  return {
    userId: login.body.data.user.id,
    token: login.body.data.accessToken,
  };
}
```

- [ ] **Step 3: Commit**

```bash
git add backend/src/__tests__/helpers/
git commit -m "test: add integration test helpers (testApp + registerAndLogin)"
```

### Task 14: Test ad-hoc session start

**Files:**
- Create: `backend/src/__tests__/sessions/start-adhoc.test.ts`

- [ ] **Step 1: Write the failing test**

```typescript
import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('POST /api/v1/sessions/start — ad-hoc', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'adhoc');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('starts an ad-hoc session with just activityName', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ activityName: 'reading the brothers karamazov' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.subjectId).toBeNull();
    expect(res.body.data.semesterId).toBeNull();
    expect(res.body.data.activityName).toBe('reading the brothers karamazov');
    expect(res.body.data.status).toBe('ACTIVE');

    // Cleanup so next test isn't blocked by an active session
    const stopRes = await request(app)
      .post(`/api/v1/sessions/${res.body.data.id}/stop`)
      .set('Authorization', `Bearer ${token}`)
      .send();
    expect(stopRes.status).toBe(200);
  });

  it('rejects starting with neither subjectId nor activityName', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(400);
  });

  it('rejects starting with both subjectId and activityName', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({
        subjectId: '00000000-0000-0000-0000-000000000000',
        activityName: 'something',
      });

    expect(res.status).toBe(400);
  });

  it('trims activityName and rejects whitespace-only', async () => {
    const res = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ activityName: '   ' });

    expect(res.status).toBe(400);
  });
});
```

- [ ] **Step 2: Make sure the DB is up**

Run from repo root: `docker compose up -d` (if not already running).
Ensure `backend/.env` points to `localhost:3307` per CLAUDE.md.

- [ ] **Step 3: Run the test**

Run from `backend/`: `npx jest src/__tests__/sessions/start-adhoc.test.ts -v`
Expected: 4 tests pass.

- [ ] **Step 4: Commit**

```bash
git add backend/src/__tests__/sessions/start-adhoc.test.ts
git commit -m "test: cover ad-hoc session start happy path + 4 rejections"
```

### Task 15: Test orphan-on-subject-delete

**Files:**
- Create: `backend/src/__tests__/subjects/delete-orphan.test.ts`

- [ ] **Step 1: Write the test**

```typescript
import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('DELETE /api/v1/subjects/:id — orphan flow', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'orphan');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('orphans sessions to ad-hoc when deleting a subject with history', async () => {
    // Setup: semester + subject + completed session
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'fall 2026',
        startDate: '2026-08-01',
        endDate: '2026-12-15',
      });
    expect(sem.status).toBe(201);

    const subj = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'calculus 101',
        color: '#A23B5C',
        semesterId: sem.body.data.id,
      });
    expect(subj.status).toBe(201);

    const startRes = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ subjectId: subj.body.data.id });
    expect(startRes.status).toBe(201);

    const stopRes = await request(app)
      .post(`/api/v1/sessions/${startRes.body.data.id}/stop`)
      .set('Authorization', `Bearer ${token}`)
      .send();
    expect(stopRes.status).toBe(200);

    // Delete the subject
    const del = await request(app)
      .delete(`/api/v1/subjects/${subj.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(200);
    expect(del.body.data.orphanedSessionCount).toBe(1);

    // Verify the session still exists, now ad-hoc
    const sessions = await request(app)
      .get('/api/v1/sessions')
      .set('Authorization', `Bearer ${token}`);
    expect(sessions.status).toBe(200);

    const orphaned = sessions.body.data.find(
      (s: { id: string }) => s.id === startRes.body.data.id
    );
    expect(orphaned).toBeDefined();
    expect(orphaned.subjectId).toBeNull();
    expect(orphaned.semesterId).toBeNull();
    expect(orphaned.activityName).toBe('calculus 101');
  });

  it('clean-deletes a subject with zero sessions', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'spring 2027',
        startDate: '2027-01-15',
        endDate: '2027-05-15',
      });
    const subj = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'history',
        color: '#3E5C7A',
        semesterId: sem.body.data.id,
      });

    const del = await request(app)
      .delete(`/api/v1/subjects/${subj.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(200);
    expect(del.body.data.orphanedSessionCount).toBe(0);
  });
});
```

- [ ] **Step 2: Run the test**

Run from `backend/`: `npx jest src/__tests__/subjects/delete-orphan.test.ts -v`
Expected: 2 tests pass.

- [ ] **Step 3: Commit**

```bash
git add backend/src/__tests__/subjects/delete-orphan.test.ts
git commit -m "test: cover subject delete orphan-to-ad-hoc flow"
```

### Task 16: Test cascade-orphan on semester delete + active-block

**Files:**
- Create: `backend/src/__tests__/semesters/delete-cascade.test.ts`

- [ ] **Step 1: Write the test**

```typescript
import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('DELETE /api/v1/semesters/:id — cascade orphan', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'semdel');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('cascades subject deletion and orphans sessions', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'summer 2026',
        startDate: '2026-06-01',
        endDate: '2026-08-15',
      });

    const s1 = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'a', color: '#7A8C3E', semesterId: sem.body.data.id });
    const s2 = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({ name: 'b', color: '#E8A33D', semesterId: sem.body.data.id });

    // 2 completed sessions: one against s1, one against s2
    for (const subjId of [s1.body.data.id, s2.body.data.id]) {
      const st = await request(app)
        .post('/api/v1/sessions/start')
        .set('Authorization', `Bearer ${token}`)
        .send({ subjectId: subjId });
      await request(app)
        .post(`/api/v1/sessions/${st.body.data.id}/stop`)
        .set('Authorization', `Bearer ${token}`)
        .send();
    }

    // Deactivate the semester first (active deletion is blocked)
    await request(app)
      .put(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isActive: false });

    const del = await request(app)
      .delete(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(200);
    expect(del.body.data.orphanedSubjectCount).toBe(2);
    expect(del.body.data.orphanedSessionCount).toBe(2);

    // Sessions still exist as ad-hoc
    const sessions = await request(app)
      .get('/api/v1/sessions')
      .set('Authorization', `Bearer ${token}`);
    const adhocNames = sessions.body.data
      .filter((s: { activityName: string | null }) => s.activityName !== null)
      .map((s: { activityName: string }) => s.activityName)
      .sort();
    expect(adhocNames).toEqual(['a', 'b']);
  });

  it('rejects deleting an active semester', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'active-blocked',
        startDate: '2026-09-01',
        endDate: '2026-12-15',
      });

    // Make it active explicitly
    await request(app)
      .put(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ isActive: true });

    const del = await request(app)
      .delete(`/api/v1/semesters/${sem.body.data.id}`)
      .set('Authorization', `Bearer ${token}`);

    expect(del.status).toBe(400);
  });
});
```

- [ ] **Step 2: Run the test**

Run from `backend/`: `npx jest src/__tests__/semesters/delete-cascade.test.ts -v`
Expected: 2 tests pass.

- [ ] **Step 3: Commit**

```bash
git add backend/src/__tests__/semesters/delete-cascade.test.ts
git commit -m "test: cover semester cascade-orphan delete + active-block"
```

### Task 17: Test `GET /semesters/:id/stats`

**Files:**
- Create: `backend/src/__tests__/semesters/stats.test.ts`

- [ ] **Step 1: Write the test**

```typescript
import request from 'supertest';
import { Application } from 'express';
import { getTestApp, closeTestApp } from '../helpers/testApp';
import { registerAndLogin } from '../helpers/auth';

describe('GET /api/v1/semesters/:id/stats', () => {
  let app: Application;
  let token: string;

  beforeAll(async () => {
    app = await getTestApp();
    const auth = await registerAndLogin(app, 'stats');
    token = auth.token;
  });

  afterAll(async () => {
    await closeTestApp();
  });

  it('returns subject + session + total time for a semester', async () => {
    const sem = await request(app)
      .post('/api/v1/semesters')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'stats term',
        startDate: '2026-09-01',
        endDate: '2026-12-15',
      });

    const subj = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 's',
        color: '#A23B5C',
        semesterId: sem.body.data.id,
      });

    const st = await request(app)
      .post('/api/v1/sessions/start')
      .set('Authorization', `Bearer ${token}`)
      .send({ subjectId: subj.body.data.id });
    await new Promise((r) => setTimeout(r, 1100)); // accumulate ~1s
    await request(app)
      .post(`/api/v1/sessions/${st.body.data.id}/stop`)
      .set('Authorization', `Bearer ${token}`)
      .send();

    const stats = await request(app)
      .get(`/api/v1/semesters/${sem.body.data.id}/stats`)
      .set('Authorization', `Bearer ${token}`);

    expect(stats.status).toBe(200);
    expect(stats.body.data.subjectCount).toBe(1);
    expect(stats.body.data.sessionCount).toBe(1);
    expect(stats.body.data.totalSeconds).toBeGreaterThanOrEqual(1);
  });

  it('404s on unknown semester id', async () => {
    const res = await request(app)
      .get('/api/v1/semesters/00000000-0000-0000-0000-000000000000/stats')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(404);
  });
});
```

- [ ] **Step 2: Run the test**

Run from `backend/`: `npx jest src/__tests__/semesters/stats.test.ts -v`
Expected: 2 tests pass.

- [ ] **Step 3: Commit**

```bash
git add backend/src/__tests__/semesters/stats.test.ts
git commit -m "test: cover GET /semesters/:id/stats"
```

### Task 18: Run full backend test suite + manual smoke test

- [ ] **Step 1: Run all tests**

Run from `backend/`: `npm test`
Expected: all tests pass; no errors during teardown.

- [ ] **Step 2: Start dev server**

Run from `backend/`: `npm run dev`
Expected: server starts, listens on port 3000, prints "Database connection established."

- [ ] **Step 3: Smoke check the new endpoint manually**

Open another shell. Register a test user via curl, log in, create a semester, then hit the stats endpoint.

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"smoke@test.local","password":"Password123!","name":"smoke"}' \
  | jq -r '.data.tokens.accessToken // empty')

[ -z "$TOKEN" ] && TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"smoke@test.local","password":"Password123!"}' \
  | jq -r '.data.accessToken')

SEM_ID=$(curl -s -X POST http://localhost:3000/api/v1/semesters \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"smoke","startDate":"2026-08-01","endDate":"2026-12-15"}' \
  | jq -r '.data.id')

curl -s "http://localhost:3000/api/v1/semesters/$SEM_ID/stats" \
  -H "Authorization: Bearer $TOKEN" | jq
```

Expected: `{ "success": true, "data": { "subjectCount": 0, "sessionCount": 0, "totalSeconds": 0 } }`.

Stop the dev server with Ctrl+C.

- [ ] **Step 4: Commit (if any drift was patched while smoking)**

If everything was clean, no commit needed. Otherwise:

```bash
git add backend/
git commit -m "chore: post-smoke fix"
```

---

## Phase 5 — Mobile: domain models (session + payloads + semester stats)

### Task 19: Update `StudySession` domain model for nullable subjectId + activityName

**Files:**
- Modify: `mobile/lib/src/domain/models/session/study_session.dart`

- [ ] **Step 1: Replace the file**

```dart
enum SessionStatus { active, paused, completed }

class StudySession {
  StudySession({
    required this.id,
    required this.subjectId,
    required this.activityName,
    required this.startTime,
    required this.status,
    required this.accumulatedPauseTime,
    required this.breakCount,
    this.endTime,
    this.pausedAt,
    this.totalDuration,
    this.effectiveStudyTime,
  }) : assert(
          (subjectId == null) != (activityName == null),
          'StudySession must have exactly one of subjectId or activityName',
        );

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String?,
        activityName: json['activityName'] as String?,
        startTime: DateTime.parse(json['startTime'] as String).toLocal(),
        endTime: json['endTime'] == null
            ? null
            : DateTime.parse(json['endTime'] as String).toLocal(),
        pausedAt: json['pausedAt'] == null
            ? null
            : DateTime.parse(json['pausedAt'] as String).toLocal(),
        status: _parseStatus(json['status']),
        accumulatedPauseTime: (json['accumulatedPauseTime'] as num?)?.toInt() ?? 0,
        breakCount: (json['breakCount'] as num?)?.toInt() ?? 0,
        totalDuration: (json['totalDuration'] as num?)?.toInt(),
        effectiveStudyTime: (json['effectiveStudyTime'] as num?)?.toInt(),
      );

  final String id;
  final String? subjectId;
  final String? activityName;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pausedAt;
  final SessionStatus status;
  final int accumulatedPauseTime;
  final int breakCount;
  final int? totalDuration;
  final int? effectiveStudyTime;

  /// True when this session has no subject — its label is `activityName` and
  /// it aggregates into the dashboard's "other" totals row.
  bool get isAdHoc => subjectId == null;

  /// What the UI shows in the chip slot / history row in place of a subject
  /// name. For subject sessions, the caller resolves the subject and renders
  /// its name; for ad-hoc, this is the typed activity name.
  String get adHocLabel => activityName ?? '';

  int effectiveElapsedAt(DateTime now) {
    final reference = switch (status) {
      SessionStatus.active => now,
      SessionStatus.paused => pausedAt ?? now,
      SessionStatus.completed => endTime ?? now,
    };
    final wallClock =
        reference.difference(startTime).inSeconds - accumulatedPauseTime;
    return wallClock < 0 ? 0 : wallClock;
  }

  static SessionStatus _parseStatus(dynamic raw) {
    final value = (raw as String?)?.toUpperCase();
    return switch (value) {
      'ACTIVE' => SessionStatus.active,
      'PAUSED' => SessionStatus.paused,
      'COMPLETED' => SessionStatus.completed,
      _ => SessionStatus.completed,
    };
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze`
Expected: errors in many call sites (`session.subjectId` being treated as non-null elsewhere). That's expected — we'll fix them in later tasks. The model file itself should not have analyze errors.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/domain/models/session/study_session.dart
git commit -m "feat(mobile): StudySession.subjectId nullable + activityName

Assertion enforces invariant that exactly one of subjectId or activityName
is set. Other files break until updated."
```

### Task 20: Update `StartSessionPayload` to support ad-hoc

**Files:**
- Modify: `mobile/lib/src/domain/models/session/session_payload.dart`

- [ ] **Step 1: Replace the file**

```dart
class StartSessionPayload {
  /// Subject-attached session.
  StartSessionPayload.forSubject({required String subjectId, String? semesterId})
      : subjectId = subjectId,
        semesterId = semesterId,
        activityName = null;

  /// Ad-hoc session (no subject, free-text activity).
  StartSessionPayload.adHoc({required String activityName})
      : subjectId = null,
        semesterId = null,
        activityName = activityName;

  final String? subjectId;
  final String? semesterId;
  final String? activityName;

  Map<String, dynamic> toJson() => {
        if (subjectId != null) 'subjectId': subjectId,
        if (semesterId != null) 'semesterId': semesterId,
        if (activityName != null) 'activityName': activityName,
      };
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/src/domain/models/session/session_payload.dart
git commit -m "feat(mobile): split StartSessionPayload into forSubject + adHoc"
```

### Task 21: Add `SemesterUpdatePayload` to semester payloads

**Files:**
- Modify: `mobile/lib/src/domain/models/semester/semester_payload.dart`

- [ ] **Step 1: Append the new class to the file**

After the existing `SemesterCreatePayload` class, add:

```dart
class SemesterUpdatePayload {
  SemesterUpdatePayload({
    this.name,
    this.startDate,
    this.endDate,
    this.isActive,
  });

  final String? name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (startDate != null) 'startDate': _formatDate(startDate!),
        if (endDate != null) 'endDate': _formatDate(endDate!),
        if (isActive != null) 'isActive': isActive,
      };

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/src/domain/models/semester/semester_payload.dart
git commit -m "feat(mobile): add SemesterUpdatePayload"
```

### Task 22: Add `SemesterStats` model

**Files:**
- Create: `mobile/lib/src/domain/models/semester/semester_stats.dart`

- [ ] **Step 1: Write the model**

```dart
class SemesterStats {
  const SemesterStats({
    required this.subjectCount,
    required this.sessionCount,
    required this.totalSeconds,
  });

  factory SemesterStats.fromJson(Map<String, dynamic> json) => SemesterStats(
        subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
        sessionCount: (json['sessionCount'] as num?)?.toInt() ?? 0,
        totalSeconds: (json['totalSeconds'] as num?)?.toInt() ?? 0,
      );

  final int subjectCount;
  final int sessionCount;
  final int totalSeconds;
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/src/domain/models/semester/semester_stats.dart
git commit -m "feat(mobile): add SemesterStats model"
```

### Task 23: Expand `ISemesterRepository` interface

**Files:**
- Modify: `mobile/lib/src/domain/repositories/semester_repository_intf.dart`

- [ ] **Step 1: Replace the interface**

```dart
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';

abstract class ISemesterRepository {
  Future<APIListResponse<Semester>> getAll();
  Future<APIResponse<Semester?>> getActive();
  Future<APIResponse<Semester>> create({required SemesterCreatePayload payload});
  Future<APIResponse<Semester>> update({
    required String id,
    required SemesterUpdatePayload payload,
  });
  Future<APIResponse<void>> delete({required String id});
  Future<APIResponse<SemesterStats>> getStats({required String id});
}
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/src/domain/repositories/semester_repository_intf.dart
git commit -m "feat(mobile): expand ISemesterRepository with update/delete/getStats"
```

### Task 24: Implement the new `SemesterRepository` methods

**Files:**
- Modify: `mobile/lib/src/data/repositories/semester_repository.dart`

- [ ] **Step 1: Replace the file**

```dart
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';
import 'package:study_time_tracker/src/domain/services/api_service_intf.dart';

class SemesterRepository implements ISemesterRepository {
  SemesterRepository(this._apiService);

  final IApiService _apiService;

  @override
  Future<APIListResponse<Semester>> getAll() {
    return _apiService.getList<Semester>(
      path: '/semesters',
      fromJson: Semester.fromJson,
      successMessage: 'Semesters loaded',
    );
  }

  @override
  Future<APIResponse<Semester?>> getActive() {
    return _apiService.getNullable<Semester>(
      path: '/semesters/active',
      fromJson: Semester.fromJson,
      successMessage: 'Active semester loaded',
    );
  }

  @override
  Future<APIResponse<Semester>> create({required SemesterCreatePayload payload}) {
    return _apiService.post<Semester>(
      path: '/semesters',
      body: payload.toJson(),
      fromJson: Semester.fromJson,
      successMessage: 'Semester created',
    );
  }

  @override
  Future<APIResponse<Semester>> update({
    required String id,
    required SemesterUpdatePayload payload,
  }) {
    return _apiService.put<Semester>(
      path: '/semesters/$id',
      body: payload.toJson(),
      fromJson: Semester.fromJson,
      successMessage: 'Semester updated',
    );
  }

  @override
  Future<APIResponse<void>> delete({required String id}) {
    return _apiService.delete<void>(
      path: '/semesters/$id',
      successMessage: 'Semester deleted',
    );
  }

  @override
  Future<APIResponse<SemesterStats>> getStats({required String id}) {
    return _apiService.get<SemesterStats>(
      path: '/semesters/$id/stats',
      fromJson: SemesterStats.fromJson,
      successMessage: 'Semester stats loaded',
    );
  }
}
```

Note: if `IApiService` does not already have a `delete` or `put` method, check `mobile/lib/src/data/services/dio_api_service.dart` for the actual method names — adapt to whatever is exposed. If `delete` doesn't exist, you may need to add a generic `delete<T>(path, successMessage)` method (and the corresponding signature on `IApiService`). Same for `put` and `get`.

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/data/repositories/semester_repository.dart`
Expected: file compiles. If `_apiService.delete` or `_apiService.put` doesn't exist, follow the note above and patch `DioApiService` / `IApiService` first.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/data/
git commit -m "feat(mobile): implement SemesterRepository.update/delete/getStats"
```

---

## Phase 6 — Mobile: state (cubits)

### Task 25: Create `SemestersCubit` + state

**Files:**
- Create: `mobile/lib/src/presentation/modules/study/semesters/services/semesters_cubit.dart`
- Create: `mobile/lib/src/presentation/modules/study/semesters/services/semesters_state.dart`

- [ ] **Step 1: Write the state file**

```dart
// mobile/lib/src/presentation/modules/study/semesters/services/semesters_state.dart
part of 'semesters_cubit.dart';

sealed class SemestersState extends Equatable {
  const SemestersState();

  @override
  List<Object?> get props => const [];
}

class SemestersInitial extends SemestersState {
  const SemestersInitial();
}

class SemestersLoading extends SemestersState {
  const SemestersLoading();
}

class SemestersLoaded extends SemestersState {
  const SemestersLoaded({
    required this.semesters,
    this.activeSemesterId,
    this.mutating = false,
    this.mutationError,
  });

  final List<Semester> semesters;
  final String? activeSemesterId;
  final bool mutating;
  final String? mutationError;

  Semester? get activeSemester {
    if (activeSemesterId == null) return null;
    for (final s in semesters) {
      if (s.id == activeSemesterId) return s;
    }
    return null;
  }

  List<Semester> get pastTerms => semesters
      .where((s) => s.id != activeSemesterId)
      .toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));

  SemestersLoaded copyWith({
    List<Semester>? semesters,
    String? activeSemesterId,
    bool? mutating,
    String? mutationError,
    bool clearActive = false,
    bool clearError = false,
  }) {
    return SemestersLoaded(
      semesters: semesters ?? this.semesters,
      activeSemesterId: clearActive
          ? null
          : (activeSemesterId ?? this.activeSemesterId),
      mutating: mutating ?? this.mutating,
      mutationError: clearError ? null : (mutationError ?? this.mutationError),
    );
  }

  @override
  List<Object?> get props =>
      [semesters, activeSemesterId, mutating, mutationError];
}

class SemestersError extends SemestersState {
  const SemestersError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
```

- [ ] **Step 2: Write the cubit file**

```dart
// mobile/lib/src/presentation/modules/study/semesters/services/semesters_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';

part 'semesters_state.dart';

class SemestersCubit extends Cubit<SemestersState> {
  SemestersCubit({required this.semesterRepository})
      : super(const SemestersInitial());

  final ISemesterRepository semesterRepository;

  Future<void> load() async {
    try {
      emit(const SemestersLoading());
      final response = await semesterRepository.getAll();
      if (!response.success) {
        emit(SemestersError(errorMessage: response.message));
        return;
      }
      final semesters = response.data;
      final active = semesters.where((s) => s.isActive).toList();
      emit(SemestersLoaded(
        semesters: semesters,
        activeSemesterId: active.isEmpty ? null : active.first.id,
      ));
    } catch (e) {
      emit(SemestersError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<Semester?> create({required SemesterCreatePayload payload}) async {
    final current = state;
    if (current is! SemestersLoaded && current is! SemestersInitial) {
      return null;
    }
    final loaded = current is SemestersLoaded
        ? current
        : const SemestersLoaded(semesters: []);

    emit(loaded.copyWith(mutating: true, clearError: true));
    try {
      final response = await semesterRepository.create(payload: payload);
      if (!response.success || response.data == null) {
        emit(loaded.copyWith(mutating: false, mutationError: response.message));
        return null;
      }
      // Reload from server to pick up the auto-active state if applicable.
      await load();
      return response.data;
    } catch (e) {
      emit(loaded.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
      return null;
    }
  }

  Future<Semester?> update({
    required String id,
    required SemesterUpdatePayload payload,
  }) async {
    final current = state;
    if (current is! SemestersLoaded) return null;
    emit(current.copyWith(mutating: true, clearError: true));
    try {
      final response = await semesterRepository.update(id: id, payload: payload);
      if (!response.success || response.data == null) {
        emit(current.copyWith(mutating: false, mutationError: response.message));
        return null;
      }
      final updated = response.data!;
      final updatedList = [
        for (final s in current.semesters) if (s.id == id) updated else s,
      ];
      // If isActive flipped, recompute activeSemesterId. The server enforces
      // at-most-one-active per user, so if we just activated one, deactivate
      // the others locally too via reload.
      if (payload.isActive == true) {
        await load();
      } else {
        emit(current.copyWith(
          semesters: updatedList,
          mutating: false,
          activeSemesterId: updated.isActive ? updated.id : current.activeSemesterId,
        ));
      }
      return updated;
    } catch (e) {
      emit(current.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
      return null;
    }
  }

  Future<bool> activate({required String id}) async {
    final updated = await update(
      id: id,
      payload: SemesterUpdatePayload(isActive: true),
    );
    return updated != null;
  }

  Future<bool> delete({required String id}) async {
    final current = state;
    if (current is! SemestersLoaded) return false;
    // Defensive: refuse if it's the active one (server also enforces this).
    if (current.activeSemesterId == id) {
      emit(current.copyWith(
        mutationError: 'Switch active to another term before deleting.',
      ));
      return false;
    }
    emit(current.copyWith(mutating: true, clearError: true));
    try {
      final response = await semesterRepository.delete(id: id);
      if (!response.success) {
        emit(current.copyWith(mutating: false, mutationError: response.message));
        return false;
      }
      emit(current.copyWith(
        semesters: current.semesters.where((s) => s.id != id).toList(),
        mutating: false,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
      return false;
    }
  }

  Future<SemesterStats?> getStats({required String id}) async {
    try {
      final response = await semesterRepository.getStats(id: id);
      if (!response.success) return null;
      return response.data;
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 3: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/semesters/`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/semesters/services/
git commit -m "feat(mobile): add SemestersCubit + state

Tracks the list, the active id, mutation status, and exposes load / create /
update / activate / delete / getStats. Reloads from server after create /
activate so the server's at-most-one-active invariant is reflected locally."
```

### Task 26: Write `SemestersCubit` tests

**Files:**
- Create: `mobile/test/semesters_cubit_test.dart`

- [ ] **Step 1: Write the test file**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';
import 'package:study_time_tracker/src/domain/repositories/semester_repository_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';

class _MockSemesterRepository extends Mock implements ISemesterRepository {}

class _FakeCreatePayload extends Fake implements SemesterCreatePayload {}

class _FakeUpdatePayload extends Fake implements SemesterUpdatePayload {}

Semester semesterFor({
  required String id,
  required String name,
  bool isActive = false,
}) {
  return Semester(
    id: id,
    name: name,
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 12, 15),
    isActive: isActive,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeCreatePayload());
    registerFallbackValue(_FakeUpdatePayload());
  });

  late _MockSemesterRepository repo;

  setUp(() {
    repo = _MockSemesterRepository();
  });

  group('load', () {
    blocTest<SemestersCubit, SemestersState>(
      'emits Loading then Loaded with active id picked from is_active',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [
              semesterFor(id: 'a', name: 'a'),
              semesterFor(id: 'b', name: 'b', isActive: true),
            ],
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<SemestersLoading>(),
        isA<SemestersLoaded>()
            .having((s) => s.semesters.length, 'count', 2)
            .having((s) => s.activeSemesterId, 'activeId', 'b'),
      ],
    );

    blocTest<SemestersCubit, SemestersState>(
      'emits Loaded with null active id when no semester isActive',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [semesterFor(id: 'a', name: 'a')],
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<SemestersLoading>(),
        isA<SemestersLoaded>().having((s) => s.activeSemesterId, 'active', null),
      ],
    );
  });

  group('delete', () {
    blocTest<SemestersCubit, SemestersState>(
      'refuses to delete the active semester',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [semesterFor(id: 'a', name: 'a', isActive: true)],
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) async {
        await c.load();
        await c.delete(id: 'a');
      },
      verify: (cubit) {
        final state = cubit.state;
        expect(state, isA<SemestersLoaded>());
        expect((state as SemestersLoaded).mutationError, isNotNull);
        // Verify the delete call never reached the repo
        verifyNever(() => repo.delete(id: any(named: 'id')));
      },
    );

    blocTest<SemestersCubit, SemestersState>(
      'removes a non-active semester on successful delete',
      build: () {
        when(() => repo.getAll()).thenAnswer(
          (_) async => APIListResponse<Semester>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: [
              semesterFor(id: 'a', name: 'a', isActive: true),
              semesterFor(id: 'b', name: 'b'),
            ],
          ),
        );
        when(() => repo.delete(id: 'b')).thenAnswer(
          (_) async => APIResponse<void>(
            success: true,
            message: 'ok',
            statusCode: 200,
            data: null,
          ),
        );
        return SemestersCubit(semesterRepository: repo);
      },
      act: (c) async {
        await c.load();
        await c.delete(id: 'b');
      },
      verify: (cubit) {
        final state = cubit.state as SemestersLoaded;
        expect(state.semesters.length, 1);
        expect(state.semesters.first.id, 'a');
      },
    );
  });
}
```

- [ ] **Step 2: Run the test**

Run from `mobile/`: `flutter test test/semesters_cubit_test.dart`
Expected: 4 tests pass.

- [ ] **Step 3: Commit**

```bash
git add mobile/test/semesters_cubit_test.dart
git commit -m "test(mobile): cover SemestersCubit load + delete behavior"
```

### Task 27: Refactor `SubjectsCubit` — drop `SubjectsNoSemesters`, add `loadForSemester`

**Files:**
- Modify: `mobile/lib/src/presentation/modules/subjects/services/subjects_state.dart`
- Modify: `mobile/lib/src/presentation/modules/subjects/services/subjects_cubit.dart`

The cubit no longer owns "no semesters" as a state — it just loads subjects for whatever semester id is given (or all subjects if `null`). When the active semester changes, the shell-level `BlocListener` calls `loadForSemester(newActiveId)`. The `createSemester` method moves OUT of `SubjectsCubit` — semester management lives in `SemestersCubit`.

- [ ] **Step 1: Replace `subjects_state.dart`**

```dart
part of 'subjects_cubit.dart';

sealed class SubjectsState extends Equatable {
  const SubjectsState();

  @override
  List<Object?> get props => const [];
}

class SubjectsInitial extends SubjectsState {
  const SubjectsInitial();
}

class SubjectsLoading extends SubjectsState {
  const SubjectsLoading();
}

class SubjectsLoaded extends SubjectsState {
  const SubjectsLoaded({
    required this.subjects,
    required this.semesterId,
    this.mutationError,
  });

  /// Subjects belonging to the semester filter applied by the cubit. When
  /// `semesterId` is null (no active semester), this list is empty by design
  /// — subjects require a semester so a fresh user has none.
  final List<Subject> subjects;

  /// The semester filter applied to produce this list. Null when no semester
  /// is active (and therefore no subjects can exist yet).
  final String? semesterId;

  final String? mutationError;

  SubjectsLoaded copyWith({
    List<Subject>? subjects,
    String? semesterId,
    String? mutationError,
    bool clearError = false,
  }) {
    return SubjectsLoaded(
      subjects: subjects ?? this.subjects,
      semesterId: semesterId ?? this.semesterId,
      mutationError: clearError ? null : (mutationError ?? this.mutationError),
    );
  }

  @override
  List<Object?> get props => [subjects, semesterId, mutationError];
}

class SubjectsError extends SubjectsState {
  const SubjectsError({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}
```

- [ ] **Step 2: Replace `subjects_cubit.dart`**

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';

part 'subjects_state.dart';

class SubjectsCubit extends Cubit<SubjectsState> {
  SubjectsCubit({required this.subjectRepository})
      : super(const SubjectsInitial());

  final ISubjectRepository subjectRepository;

  /// Load all subjects, optionally filtered to a semester. Pass null to clear
  /// to "no active semester, no subjects."
  Future<void> loadForSemester(String? semesterId) async {
    try {
      emit(const SubjectsLoading());
      if (semesterId == null) {
        emit(const SubjectsLoaded(subjects: [], semesterId: null));
        return;
      }
      final response = await subjectRepository.getAll();
      final filtered = response.data
          .where((s) => s.semesterId == semesterId)
          .toList();
      emit(SubjectsLoaded(subjects: filtered, semesterId: semesterId));
    } catch (e) {
      emit(SubjectsError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  Future<bool> createSubject({required SubjectCreatePayload payload}) async {
    final current = state;
    if (current is! SubjectsLoaded) return false;
    try {
      final response = await subjectRepository.create(payload: payload);
      if (!response.success || response.data == null) {
        emit(current.copyWith(mutationError: response.message));
        return false;
      }
      // Only add to the local list if this subject belongs to the current
      // semester filter. Otherwise it's a subject created during semester
      // switch — load will reconcile.
      if (response.data!.semesterId == current.semesterId) {
        emit(current.copyWith(
          subjects: [...current.subjects, response.data!],
          clearError: true,
        ));
      }
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }

  Future<bool> updateSubject({
    required String id,
    required SubjectUpdatePayload payload,
  }) async {
    final current = state;
    if (current is! SubjectsLoaded) return false;
    try {
      final response = await subjectRepository.update(id: id, payload: payload);
      if (!response.success || response.data == null) {
        emit(current.copyWith(mutationError: response.message));
        return false;
      }
      final next = response.data!;
      emit(current.copyWith(
        subjects: [
          for (final s in current.subjects)
            if (s.id == id) next else s,
        ],
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }

  Future<bool> deleteSubject({required String id}) async {
    final current = state;
    if (current is! SubjectsLoaded) return false;
    try {
      final response = await subjectRepository.delete(id: id);
      if (!response.success) {
        emit(current.copyWith(mutationError: response.message));
        return false;
      }
      emit(current.copyWith(
        subjects: current.subjects.where((s) => s.id != id).toList(),
        clearError: true,
      ));
      return true;
    } catch (e) {
      emit(current.copyWith(mutationError: CoreUtils.getErrorMessage(e)));
      return false;
    }
  }
}
```

- [ ] **Step 3: Update DI registration**

The cubit no longer depends on `ISemesterRepository`. Modify `mobile/lib/core/utils/injection_container.dart`. Find:

```dart
sl.registerFactory(
  () => SubjectsCubit(
    subjectRepository: sl<ISubjectRepository>(),
    semesterRepository: sl<ISemesterRepository>(),
  ),
);
```

Replace with:

```dart
sl.registerFactory(
  () => SubjectsCubit(subjectRepository: sl<ISubjectRepository>()),
);
```

- [ ] **Step 4: Run analyze**

Run from `mobile/`: `flutter analyze`
Expected: many errors will surface in `subjects_list_screen.dart`, `dashboard_screen.dart`, and possibly other call sites that referenced `SubjectsNoSemesters` or `state.semesters` / `state.activeSemesterId` / `state.semesterFor()`. These are fixed in later tasks.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/src/presentation/modules/subjects/services/ \
        mobile/lib/core/utils/injection_container.dart
git commit -m "refactor(mobile): SubjectsCubit no longer owns semesters

Drops SubjectsNoSemesters state and the createSemester method. New
loadForSemester(String? semesterId) loads subjects filtered to a semester
(or emits an empty list when null). Semester management moves entirely
to SemestersCubit. Screens depending on the old state shape break until
patched."
```

### Task 28: Write `SubjectsCubit` refactor tests

**Files:**
- Create: `mobile/test/subjects_cubit_test.dart`

- [ ] **Step 1: Write the test**

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:study_time_tracker/core/api/api_response.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/repositories/subject_repository_intf.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';

class _MockSubjectRepository extends Mock implements ISubjectRepository {}

Subject subjectFor({
  required String id,
  required String semesterId,
  String name = 's',
  String color = '#A23B5C',
}) {
  return Subject(
    id: id,
    userId: 'u',
    semesterId: semesterId,
    name: name,
    color: color,
    icon: null,
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

void main() {
  late _MockSubjectRepository repo;

  setUp(() {
    repo = _MockSubjectRepository();
  });

  blocTest<SubjectsCubit, SubjectsState>(
    'loadForSemester(null) emits Loaded with empty list',
    build: () => SubjectsCubit(subjectRepository: repo),
    act: (c) => c.loadForSemester(null),
    expect: () => [
      isA<SubjectsLoading>(),
      isA<SubjectsLoaded>()
          .having((s) => s.subjects.length, 'subjects', 0)
          .having((s) => s.semesterId, 'semesterId', null),
    ],
  );

  blocTest<SubjectsCubit, SubjectsState>(
    'loadForSemester(id) filters to that semester',
    build: () {
      when(() => repo.getAll()).thenAnswer(
        (_) async => APIListResponse<Subject>(
          success: true,
          message: 'ok',
          statusCode: 200,
          data: [
            subjectFor(id: '1', semesterId: 'sem-a'),
            subjectFor(id: '2', semesterId: 'sem-b'),
            subjectFor(id: '3', semesterId: 'sem-a'),
          ],
        ),
      );
      return SubjectsCubit(subjectRepository: repo);
    },
    act: (c) => c.loadForSemester('sem-a'),
    expect: () => [
      isA<SubjectsLoading>(),
      isA<SubjectsLoaded>()
          .having((s) => s.subjects.length, 'count', 2)
          .having(
            (s) => s.subjects.map((x) => x.id).toList(),
            'ids',
            ['1', '3'],
          )
          .having((s) => s.semesterId, 'semesterId', 'sem-a'),
    ],
  );
}
```

- [ ] **Step 2: Run the test**

Run from `mobile/`: `flutter test test/subjects_cubit_test.dart`
Expected: 2 tests pass.

- [ ] **Step 3: Commit**

```bash
git add mobile/test/subjects_cubit_test.dart
git commit -m "test(mobile): cover SubjectsCubit.loadForSemester filtering"
```

### Task 29: Add `ActiveSessionCubit.startAdHoc`

**Files:**
- Modify: `mobile/lib/src/presentation/modules/study/dashboard/services/active_session_cubit.dart`

The existing `start({required String subjectId, String? semesterId})` method also needs to refactor because `_computeTodayTotals` reads `s.subjectId` which is now nullable.

- [ ] **Step 1: Replace the cubit**

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/session/session_payload.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/repositories/session_repository_intf.dart';

part 'active_session_state.dart';

class ActiveSessionCubit extends Cubit<ActiveSessionState> {
  ActiveSessionCubit({required this.sessionRepository})
      : super(const ActiveSessionInitial());

  final ISessionRepository sessionRepository;

  Future<void> checkActive() async {
    try {
      emit(const ActiveSessionChecking());
      final active = await sessionRepository.getActive();
      final today = await _computeTodayTotals();
      final session = active.data;
      if (session == null) {
        emit(ActiveSessionIdle(
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ));
        return;
      }
      emit(_runningOrPaused(session, today));
    } catch (e) {
      emit(ActiveSessionError(errorMessage: CoreUtils.getErrorMessage(e)));
    }
  }

  /// Start a subject-attached session.
  Future<void> start({required String subjectId}) async {
    await _startWithPayload(
      StartSessionPayload.forSubject(subjectId: subjectId),
    );
  }

  /// Start an ad-hoc session with the given activity name.
  Future<void> startAdHoc({required String activityName}) async {
    final trimmed = activityName.trim();
    if (trimmed.isEmpty) return;
    await _startWithPayload(
      StartSessionPayload.adHoc(activityName: trimmed),
    );
  }

  Future<void> _startWithPayload(StartSessionPayload payload) async {
    final prev = state;
    if (prev is! ActiveSessionIdle) return;
    try {
      emit(prev.copyWith(mutating: true));
      final response = await sessionRepository.start(payload: payload);
      final session = response.data;
      if (session == null) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: response.message,
        ));
        return;
      }
      emit(_runningOrPaused(
        session,
        _TodayTotals(prev.todaySeconds, prev.todaySubjectCount),
      ));
    } catch (e) {
      emit(prev.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
    }
  }

  Future<void> pause() async {
    final prev = state;
    if (prev is! ActiveSessionRunning) return;
    try {
      emit(prev.copyWith(mutating: true));
      final response = await sessionRepository.pause(id: prev.session.id);
      final session = response.data;
      if (session == null) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: response.message,
        ));
        return;
      }
      emit(_runningOrPaused(
        session,
        _TodayTotals(prev.todaySeconds, prev.todaySubjectCount),
      ));
    } catch (e) {
      emit(prev.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
    }
  }

  Future<void> resume() async {
    final prev = state;
    if (prev is! ActiveSessionPaused) return;
    try {
      emit(prev.copyWith(mutating: true));
      final response = await sessionRepository.resume(id: prev.session.id);
      final session = response.data;
      if (session == null) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: response.message,
        ));
        return;
      }
      emit(_runningOrPaused(
        session,
        _TodayTotals(prev.todaySeconds, prev.todaySubjectCount),
      ));
    } catch (e) {
      emit(prev.copyWith(
        mutating: false,
        mutationError: CoreUtils.getErrorMessage(e),
      ));
    }
  }

  Future<StudySession?> stop() async {
    final prev = state;
    if (prev is! ActiveSessionRunning && prev is! ActiveSessionPaused) {
      return null;
    }
    final id = (prev is ActiveSessionRunning)
        ? prev.session.id
        : (prev as ActiveSessionPaused).session.id;
    try {
      if (prev is ActiveSessionRunning) {
        emit(prev.copyWith(mutating: true));
      } else if (prev is ActiveSessionPaused) {
        emit(prev.copyWith(mutating: true));
      }
      final response = await sessionRepository.stop(id: id);
      final completed = response.data;
      final today = await _computeTodayTotals();
      emit(ActiveSessionIdle(
        todaySeconds: today.seconds,
        todaySubjectCount: today.subjectCount,
      ));
      return completed;
    } catch (e) {
      if (prev is ActiveSessionRunning) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: CoreUtils.getErrorMessage(e),
        ));
      } else if (prev is ActiveSessionPaused) {
        emit(prev.copyWith(
          mutating: false,
          mutationError: CoreUtils.getErrorMessage(e),
        ));
      }
      return null;
    }
  }

  ActiveSessionState _runningOrPaused(
    StudySession session,
    _TodayTotals today,
  ) {
    return switch (session.status) {
      SessionStatus.active => ActiveSessionRunning(
          session: session,
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ),
      SessionStatus.paused => ActiveSessionPaused(
          session: session,
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ),
      SessionStatus.completed => ActiveSessionIdle(
          todaySeconds: today.seconds,
          todaySubjectCount: today.subjectCount,
        ),
    };
  }

  Future<_TodayTotals> _computeTodayTotals() async {
    final response = await sessionRepository.getAll();
    if (!response.success) return const _TodayTotals(0, 0);
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    var total = 0;
    final subjects = <String>{};
    for (final s in response.data) {
      if (s.status != SessionStatus.completed) continue;
      if (s.startTime.isBefore(startOfDay)) continue;
      total += s.effectiveStudyTime ?? 0;
      // Ad-hoc sessions don't have a subjectId, but we still want to count
      // them as a separate identity bucket for the "today across N subjects"
      // tagline. Use a stable sentinel keyed by activityName so two ad-hoc
      // sessions with the same name aren't double-counted.
      if (s.subjectId != null) {
        subjects.add(s.subjectId!);
      } else if (s.activityName != null) {
        subjects.add('adhoc:${s.activityName}');
      }
    }
    return _TodayTotals(total, subjects.length);
  }
}

class _TodayTotals {
  const _TodayTotals(this.seconds, this.subjectCount);

  final int seconds;
  final int subjectCount;
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze`
Expected: errors in `dashboard_screen.dart` (still calling old `start(subjectId:, semesterId:)`). Patched later.

- [ ] **Step 3: Run the existing cubit test**

Run from `mobile/`: `flutter test test/active_session_cubit_test.dart`
Expected: test may fail because the mocked `start(subjectId:, semesterId:)` signature no longer matches. Update the existing test file's `start` call signatures: change `c.start(subjectId: 'subj-1', semesterId: 'sem-1')` to `c.start(subjectId: 'subj-1')`. Re-run; expect pass.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/dashboard/services/active_session_cubit.dart \
        mobile/test/active_session_cubit_test.dart
git commit -m "feat(mobile): add ActiveSessionCubit.startAdHoc

start() simplifies to {subjectId}; startAdHoc(activityName) starts a session
with no subject. Today totals counter buckets ad-hoc sessions by
activityName so the 'across N subjects' caption stays sensible."
```

---

## Phase 7 — Mobile: widgets (pill, ad-hoc picker chip, session tile updates)

### Task 30: Build the `ActiveSemesterPill` widget

**Files:**
- Create: `mobile/lib/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart`

Per the locked spec — cream chip, `surfaceContainer`, 32px tall, `Radii.full`, Geist 14pt semibold ink, lowercase, no icon. Tap routes to `/semesters`. Loading state: `"…"` placeholder, no tap target. Hidden by parent when 0 semesters; this widget always renders something when given a semester.

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';

class ActiveSemesterPill extends StatelessWidget {
  const ActiveSemesterPill({super.key, required this.semester});

  /// Null while semesters are still loading. Renders the `"…"` placeholder
  /// in that case, with no tap target.
  final Semester? semester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final bg = theme.colorScheme.surfaceContainer;

    final label = semester?.name ?? '…';
    final isLoading = semester == null;

    final pill = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 32,
        maxWidth: 200,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Radii.full),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toLowerCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: kFontGeist,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ink,
            height: 1.0,
          ),
        ),
      ),
    );

    if (isLoading) return pill;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Radii.full),
      child: InkWell(
        onTap: () => context.push('/semesters'),
        borderRadius: BorderRadius.circular(Radii.full),
        child: pill,
      ),
    );
  }
}
```

Note: This file assumes `kFontGeist` is exported from `themes.dart`. If not, replace with the actual constant used elsewhere (search `kFont` in `themes.dart` to find the right symbol).

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart
git commit -m "feat(mobile): add ActiveSemesterPill widget

Cream surfaceContainer chip per the locked spec — 32px tall, Radii.full,
lowercase Geist 14pt semibold ink. Tap routes to /semesters manager.
Renders a non-tappable '…' placeholder when no semester is provided."
```

### Task 31: Add the `"+ something else"` chip to `SubjectSelector`

**Files:**
- Modify: `mobile/lib/src/presentation/modules/study/dashboard/widgets/subject_selector.dart`

The selector becomes aware of an ad-hoc mode. When the ad-hoc row is selected, the parent (`DashboardScreen`) handles the input UX in `SessionTile`. The selector just adds a row at the end with `+ something else`.

- [ ] **Step 1: Replace the selector**

```dart
import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';

/// Sentinel value passed via [onSelectAdHoc] to indicate the user tapped the
/// "+ something else" row instead of a real subject. The parent decides what
/// to do (typically: switch the session-tile chip slot into an input field).
typedef AdHocSelectCallback = void Function();

class SubjectSelector extends StatelessWidget {
  const SubjectSelector({
    super.key,
    required this.subjects,
    required this.selectedId,
    required this.adHocSelected,
    required this.onSelect,
    required this.onSelectAdHoc,
  });

  final List<Subject> subjects;
  final String? selectedId;
  final bool adHocSelected;
  final ValueChanged<Subject> onSelect;
  final AdHocSelectCallback onSelectAdHoc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = theme.colorScheme.onSurface;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: subjects.length + 1, // +1 for the ad-hoc row
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.xs),
      itemBuilder: (context, index) {
        if (index == subjects.length) {
          return _AdHocRow(
            isSelected: adHocSelected,
            onTap: onSelectAdHoc,
          );
        }

        final subject = subjects[index];
        final brand =
            SubjectColor.fromHex(subject.color).resolve(brightness);
        final isSelected = subject.id == selectedId && !adHocSelected;

        return Material(
          color: isSelected
              ? brand.withValues(alpha: 0.08)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
            side: BorderSide(
              color: isSelected
                  ? brand
                  : ink.withValues(alpha: InkOpacity.hint),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Radii.md),
            onTap: () => onSelect(subject),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      subject.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isSelected ? brand : ink,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_rounded, color: brand, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdHocRow extends StatelessWidget {
  const _AdHocRow({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return Material(
      color: isSelected
          ? ink.withValues(alpha: 0.06)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: isSelected ? ink : ink.withValues(alpha: InkOpacity.hint),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: softInk),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'something else',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isSelected ? ink : softInk,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/dashboard/widgets/subject_selector.dart`
Expected: clean. Call sites in `dashboard_screen.dart` will fail (constructor signature change) — fixed in Task 38.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/dashboard/widgets/subject_selector.dart
git commit -m "feat(mobile): add '+ something else' ad-hoc row to SubjectSelector

Sibling row at the end of the picker. Same row geometry as subject rows,
but with a ghost + icon instead of a color dot. Selecting it fires
onSelectAdHoc — parent switches the session tile to inline input mode."
```

### Task 32: Update `SessionTile` for ad-hoc input + no-marker running state

**Files:**
- Modify: `mobile/lib/src/presentation/modules/study/dashboard/widgets/session_tile.dart`

Three changes:
1. New `adHocMode` flag — when on (and `activeSession` is null), the chip-slot becomes an inline `TextField`.
2. New `onActivityChanged` callback the parent uses to know when the field has non-empty content (to enable start).
3. The `_TileHeader` for an ad-hoc running session shows the activity name with no color dot.

- [ ] **Step 1: Replace the file**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

/// Home-tile session card. Two idle paths now: subject-picked (chip slot shows
/// the subject chip + color dot) and ad-hoc (chip slot becomes an inline
/// text field). One running path: subject sessions show the chip; ad-hoc
/// sessions show the activity name as plain Cocoa Ink text (absence of
/// color = the ad-hoc signal).
class SessionTile extends StatefulWidget {
  const SessionTile({
    super.key,
    required this.activeSession,
    required this.activeSubject,
    required this.pickedSubject,
    required this.adHocMode,
    required this.adHocController,
    required this.isPaused,
    required this.mutating,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onActivityChanged,
  });

  final StudySession? activeSession;
  final Subject? activeSubject;
  final Subject? pickedSubject;

  /// True when the user has tapped the "+ something else" row.
  final bool adHocMode;

  /// Owned by the parent so re-builds don't destroy in-flight text. The
  /// parent reads `controller.text.trim()` when wiring [onStart].
  final TextEditingController adHocController;

  final bool isPaused;
  final bool mutating;

  /// Null when start is disabled (no subject picked AND not in ad-hoc mode
  /// with non-empty text, or already mutating).
  final VoidCallback? onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  /// Fires on every text change in the ad-hoc input. Parent updates start
  /// button enabled state based on `text.trim().isNotEmpty`.
  final ValueChanged<String> onActivityChanged;

  @override
  State<SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<SessionTile> {
  bool get _isActive => widget.activeSession != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final brightness = theme.brightness;

    final displaySubject = widget.activeSubject ?? widget.pickedSubject;
    final accent = displaySubject == null
        ? null
        : SubjectColor.fromHex(displaySubject.color).resolve(brightness);

    final activeIsAdHoc = widget.activeSession?.isAdHoc ?? false;

    return PulpTile(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TileHeader(
            subject: displaySubject,
            accent: accent,
            isActive: _isActive,
            isPaused: widget.isPaused,
            adHocMode: widget.adHocMode && !_isActive,
            adHocLabel: activeIsAdHoc
                ? widget.activeSession!.activityName ?? ''
                : null,
            adHocController: widget.adHocController,
            onActivityChanged: widget.onActivityChanged,
          ),
          const SizedBox(height: Spacing.lg),
          Center(child: _TimerLine(session: widget.activeSession)),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              _subtitle(
                widget.activeSession,
                isPaused: widget.isPaused,
                hasPick: widget.pickedSubject != null,
                adHocMode: widget.adHocMode,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ink.withValues(alpha: InkOpacity.soft),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          DefaultButton(
            title: _actionLabel(isActive: _isActive, isPaused: widget.isPaused),
            fullWidth: true,
            size: ButtonSize.large,
            isLoading: widget.mutating,
            onPressed: _resolveAction(),
          ),
          if (_isActive) ...[
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: widget.mutating ? null : widget.onStop,
              style: TextButton.styleFrom(
                foregroundColor: ink.withValues(alpha: InkOpacity.soft),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
              ),
              child: const Text('end session'),
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _resolveAction() {
    if (widget.mutating) return null;
    if (_isActive) return widget.isPaused ? widget.onResume : widget.onPause;
    return widget.onStart;
  }

  String _actionLabel({required bool isActive, required bool isPaused}) {
    if (isActive) return isPaused ? 'resume' : 'pause';
    return 'start';
  }

  String _subtitle(
    StudySession? session, {
    required bool isPaused,
    required bool hasPick,
    required bool adHocMode,
  }) {
    if (session != null) {
      if (isPaused) return 'paused';
      final breaks = session.breakCount;
      final breaksLine = breaks == 0
          ? 'no breaks yet'
          : breaks == 1
              ? '1 break taken'
              : '$breaks breaks taken';
      return 'effective focus · $breaksLine';
    }
    if (adHocMode) return 'name your activity, then start';
    return hasPick ? 'ready when you are' : 'tap a subject below to start';
  }
}

class _TileHeader extends StatelessWidget {
  const _TileHeader({
    required this.subject,
    required this.accent,
    required this.isActive,
    required this.isPaused,
    required this.adHocMode,
    required this.adHocLabel,
    required this.adHocController,
    required this.onActivityChanged,
  });

  final Subject? subject;
  final Color? accent;
  final bool isActive;
  final bool isPaused;

  /// True when in idle ad-hoc input mode.
  final bool adHocMode;

  /// Non-null when there's a running ad-hoc session; renders the activity
  /// name as plain Cocoa Ink text (no chip, no color dot).
  final String? adHocLabel;

  final TextEditingController adHocController;
  final ValueChanged<String> onActivityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    Widget leading;
    if (adHocMode) {
      leading = Expanded(
        child: _AdHocInput(
          controller: adHocController,
          onChanged: onActivityChanged,
        ),
      );
    } else if (adHocLabel != null && isActive) {
      // Running ad-hoc — plain text, no chip, no dot.
      leading = Expanded(
        child: Text(
          adHocLabel!.toLowerCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(color: ink),
        ),
      );
    } else if (subject != null && accent != null) {
      leading = _SubjectChip(name: subject!.name, color: accent!);
    } else {
      leading = Expanded(
        child: Text(
          isActive ? 'session' : 'no subject picked',
          style: theme.textTheme.labelSmall?.copyWith(color: softInk),
        ),
      );
    }

    return Row(
      children: [
        leading,
        const Spacer(),
        if (isActive)
          _LiveIndicator(isPaused: isPaused)
        else
          Text(
            'ready',
            style: theme.textTheme.labelSmall?.copyWith(color: softInk),
          ),
      ],
    );
  }
}

class _AdHocInput extends StatelessWidget {
  const _AdHocInput({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return TextField(
      controller: controller,
      autofocus: true,
      maxLength: 100,
      textInputAction: TextInputAction.done,
      style: theme.textTheme.titleMedium?.copyWith(color: ink),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'what are you doing?',
        hintStyle: theme.textTheme.titleMedium?.copyWith(
          color: ink.withValues(alpha: InkOpacity.faint),
        ),
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final tintBg = brightness == Brightness.dark
        ? color.withValues(alpha: 0.20)
        : color.withValues(alpha: 0.16);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tintBg,
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            name.toLowerCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  const _LiveIndicator({required this.isPaused});

  final bool isPaused;

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    if (widget.isPaused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: softInk,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'paused',
            style: theme.textTheme.labelSmall?.copyWith(color: softInk),
          ),
        ],
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.45 + 0.55 * _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: kMatchaStain.withValues(alpha: alpha),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'live',
              style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            ),
          ],
        );
      },
    );
  }
}

class _TimerLine extends StatefulWidget {
  const _TimerLine({required this.session});

  final StudySession? session;

  @override
  State<_TimerLine> createState() => _TimerLineState();
}

class _TimerLineState extends State<_TimerLine> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(_TimerLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session?.status != widget.session?.status ||
        oldWidget.session?.id != widget.session?.id) {
      _syncTicker();
    }
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.session?.status == SessionStatus.active) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final session = widget.session;
    final seconds =
        session == null ? 0 : session.effectiveElapsedAt(DateTime.now());
    final color = session == null
        ? ink.withValues(alpha: InkOpacity.faint)
        : ink;
    return Text(
      _format(seconds),
      style: TextStyle(
        fontFamily: kFontGeistMono,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
        fontSize: 48,
        height: 1.0,
        letterSpacing: -0.5,
        color: color,
      ),
    );
  }

  String _format(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/dashboard/widgets/session_tile.dart`
Expected: clean. Dashboard screen call site still broken — patched in Task 38.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/dashboard/widgets/session_tile.dart
git commit -m "feat(mobile): SessionTile supports ad-hoc input + no-marker running

When adHocMode is true and no session is active, the subject-chip slot
becomes a TextField (autofocus, 100-char silent cap, no border). When
running an ad-hoc session, the activity name renders as plain ink text
with no chip / dot — absence of color is the ad-hoc signal."
```

### Task 33: Build the `SemesterCard` widget

**Files:**
- Create: `mobile/lib/src/presentation/modules/study/semesters/widgets/semester_card.dart`

Per locked spec — `PulpTile` cream card, name + date range, overflow `…` icon, tap-to-activate, "active" marker chip when the semester is active.

- [ ] **Step 1: Write the widget**

```dart
import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

enum SemesterCardAction { edit, delete }

class SemesterCard extends StatelessWidget {
  const SemesterCard({
    super.key,
    required this.semester,
    required this.isActive,
    required this.onActivate,
    required this.onAction,
  });

  final Semester semester;
  final bool isActive;
  final VoidCallback onActivate;
  final ValueChanged<SemesterCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return PulpTile(
      onTap: isActive ? null : onActivate,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  semester.name.toLowerCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _formatRange(semester.startDate, semester.endDate),
                  style: theme.textTheme.labelMedium?.copyWith(color: softInk),
                ),
              ],
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: Spacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kHoneyed.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(Radii.full),
              ),
              child: Text(
                'active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: kHoneyed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          PopupMenuButton<SemesterCardAction>(
            icon: Icon(Icons.more_horiz_rounded, color: softInk),
            tooltip: 'more',
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            onSelected: onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: SemesterCardAction.edit,
                child: Text('edit'),
              ),
              PopupMenuItem(
                value: SemesterCardAction.delete,
                child: Text('delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  String _formatRange(DateTime start, DateTime end) {
    final s = '${_months[start.month - 1]} ${start.day}';
    final e = '${_months[end.month - 1]} ${end.day}';
    return '$s – $e';
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/semesters/widgets/semester_card.dart`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/semesters/widgets/semester_card.dart
git commit -m "feat(mobile): add SemesterCard widget

PulpTile-backed card with name (lowercase), 'aug 24 – dec 20' range,
Honeyed 'active' chip when active, overflow menu (edit/delete). Tap
activates when not already active."
```

---

## Phase 8 — Mobile: sheets (semester form, delete preview, subject form with inline semester)

### Task 34: Build `SemesterFormSheet` (create + edit, standalone)

**Files:**
- Create: `mobile/lib/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart`

Per locked decisions #8 — bottom sheet, ~85% height, drag handle, reused for edit. "Make this the active term" toggle defaulted on when 0 active exists. On the edit path, the toggle is disabled if editing the currently-active semester (locked Q7 default).

- [ ] **Step 1: Write the sheet**

```dart
import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

/// Bottom-sheet form for creating or editing a semester. Returns
/// (`SemesterCreatePayload | SemesterUpdatePayload`, makeActive: bool) on
/// submit; the caller dispatches to the right cubit method.
class SemesterFormResult {
  const SemesterFormResult.create({required this.create, required this.makeActive})
      : update = null;
  const SemesterFormResult.update({required this.update, required this.makeActive})
      : create = null;

  final SemesterCreatePayload? create;
  final SemesterUpdatePayload? update;
  final bool makeActive;
}

Future<SemesterFormResult?> showSemesterFormSheet(
  BuildContext context, {
  Semester? editing,
  required bool noActiveYet,
}) {
  return showModalBottomSheet<SemesterFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _SemesterFormSheet(
      editing: editing,
      noActiveYet: noActiveYet,
    ),
  );
}

class _SemesterFormSheet extends StatefulWidget {
  const _SemesterFormSheet({required this.editing, required this.noActiveYet});

  final Semester? editing;
  final bool noActiveYet;

  @override
  State<_SemesterFormSheet> createState() => _SemesterFormSheetState();
}

class _SemesterFormSheetState extends State<_SemesterFormSheet> {
  late final TextEditingController _name;
  DateTime? _start;
  DateTime? _end;
  late bool _makeActive;

  bool get _isEdit => widget.editing != null;
  bool get _toggleDisabled => _isEdit && widget.editing!.isActive;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.editing?.name ?? '');
    _start = widget.editing?.startDate ?? DateTime.now();
    _end = widget.editing?.endDate ??
        DateTime.now().add(const Duration(days: 120));
    _makeActive = _isEdit
        ? widget.editing!.isActive
        : widget.noActiveYet; // first semester auto-activates
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? (_start ?? now) : (_end ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      CoreUtils.showNotification(
        message: 'name is required',
        success: false,
        context: context,
      );
      return;
    }
    if (_start == null || _end == null || !_start!.isBefore(_end!)) {
      CoreUtils.showNotification(
        message: 'start date must be before end date',
        success: false,
        context: context,
      );
      return;
    }
    if (_isEdit) {
      Navigator.of(context).pop(
        SemesterFormResult.update(
          update: SemesterUpdatePayload(
            name: name,
            startDate: _start,
            endDate: _end,
            isActive: _toggleDisabled ? null : _makeActive,
          ),
          makeActive: _makeActive && !_toggleDisabled,
        ),
      );
    } else {
      Navigator.of(context).pop(
        SemesterFormResult.create(
          create: SemesterCreatePayload(
            name: name,
            startDate: _start!,
            endDate: _end!,
          ),
          makeActive: _makeActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DragHandle(),
              const SizedBox(height: Spacing.md),
              Text(
                _isEdit ? 'edit term' : 'new term',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.lg),
              DefaultTextfield(
                controller: _name,
                label: 'term name',
                placeholder: 'fall 2026',
                textInputAction: TextInputAction.next,
                required: true,
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'start',
                      value: _start,
                      onTap: () => _pickDate(start: true),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: _DateField(
                      label: 'end',
                      value: _end,
                      onTap: () => _pickDate(start: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.lg),
              Opacity(
                opacity: _toggleDisabled ? 0.45 : 1.0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _toggleDisabled
                            ? "this is your active term — switch elsewhere to deactivate"
                            : 'make this the active term',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Switch(
                      value: _makeActive,
                      onChanged: _toggleDisabled
                          ? null
                          : (v) => setState(() => _makeActive = v),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              DefaultButton(
                title: _isEdit ? 'save changes' : 'create term',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: _submit,
              ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: softInk),
                child: const Text('cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Radii.full),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final hintInk = ink.withValues(alpha: InkOpacity.faint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.xs),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: InkOpacity.hint)),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null ? CoreUtils.formatDate(value!) : 'pick',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value != null ? ink : hintInk,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 16, color: softInk),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart
git commit -m "feat(mobile): add SemesterFormSheet (create + edit)

85%-height bottom sheet with drag handle, two-column date row, and a
'make active' toggle that's disabled when editing the active semester.
Returns SemesterFormResult.create or update so the caller dispatches
to the right cubit method."
```

### Task 35: Build `DeleteSemesterSheet` (cascade preview + orphan messaging)

**Files:**
- Create: `mobile/lib/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart`

Fetches `SemesterStats` on open and shows "X subjects · Y sessions · Z hours will be preserved as ad-hoc." Blocks deletion when the semester is the currently-active one.

- [ ] **Step 1: Write the sheet**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_stats.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

/// Returns true if the user confirmed deletion (and the cubit succeeded).
Future<bool> showDeleteSemesterSheet(
  BuildContext context, {
  required Semester semester,
  required bool isActive,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _DeleteSemesterSheet(
      semester: semester,
      isActive: isActive,
    ),
  );
  return result ?? false;
}

class _DeleteSemesterSheet extends StatefulWidget {
  const _DeleteSemesterSheet({required this.semester, required this.isActive});

  final Semester semester;
  final bool isActive;

  @override
  State<_DeleteSemesterSheet> createState() => _DeleteSemesterSheetState();
}

class _DeleteSemesterSheetState extends State<_DeleteSemesterSheet> {
  SemesterStats? _stats;
  bool _loadingStats = true;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cubit = context.read<SemestersCubit>();
      final stats = await cubit.getStats(id: widget.semester.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    });
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    final ok = await context
        .read<SemestersCubit>()
        .delete(id: widget.semester.id);
    if (!mounted) return;
    setState(() => _deleting = false);
    Navigator.of(context).pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                'delete ${widget.semester.name.toLowerCase()}?',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.md),
              if (widget.isActive)
                Text(
                  "you can't delete your active term. switch to another term first, then try again.",
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                )
              else if (_loadingStats)
                Text(
                  'checking what will be preserved…',
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                )
              else if (_stats != null && _stats!.sessionCount == 0)
                Text(
                  "this term has nothing logged against it. it'll just be removed.",
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                )
              else if (_stats != null)
                Text(
                  '${_stats!.sessionCount} session${_stats!.sessionCount == 1 ? '' : 's'} · '
                  '${CoreUtils.formatHm(_stats!.totalSeconds, dashOnZero: false)} '
                  'will be preserved as ad-hoc activities.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
                ),
              const SizedBox(height: Spacing.xl),
              if (widget.isActive)
                DefaultButton(
                  title: 'got it',
                  fullWidth: true,
                  size: ButtonSize.large,
                  onPressed: () => Navigator.of(context).pop(false),
                )
              else
                DefaultButton(
                  title: 'delete term',
                  fullWidth: true,
                  size: ButtonSize.large,
                  isLoading: _deleting,
                  onPressed: _delete,
                ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: _deleting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: softInk),
                child: const Text('cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart
git commit -m "feat(mobile): add DeleteSemesterSheet with cascade-orphan preview

Fetches stats on open, renders 'X sessions · Y hours will be preserved
as ad-hoc.' Active-semester delete is blocked at the UI with a 'switch
first' explanation."
```

### Task 36: Build `SubjectFormSheet` with inline semester section

**Files:**
- Create: `mobile/lib/src/presentation/modules/subjects/widgets/subject_form_sheet.dart`

Per locked Q7 — bottom sheet with subject fields + an "attach to a term" section. If no semesters exist, the section expands inline to capture semester fields. Both submit as one atomic transaction. The framing line *"to organize subjects, group them into a term"* sits above the inline section. Dates default today / today+120.

- [ ] **Step 1: Write the sheet**

```dart
import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_color_picker.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_textfield.dart';

class SubjectFormResult {
  const SubjectFormResult({
    required this.subject,
    required this.inlineSemester,
  });

  final SubjectCreatePayload subject;

  /// Non-null when the user filled in the inline semester section — the
  /// caller must create that semester first, then create the subject using
  /// the returned semester id.
  final SemesterCreatePayload? inlineSemester;
}

Future<SubjectFormResult?> showSubjectFormSheet(
  BuildContext context, {
  required List<Semester> availableSemesters,
  required String? defaultSemesterId,
}) {
  return showModalBottomSheet<SubjectFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg)),
    ),
    builder: (_) => _SubjectFormSheet(
      availableSemesters: availableSemesters,
      defaultSemesterId: defaultSemesterId,
    ),
  );
}

class _SubjectFormSheet extends StatefulWidget {
  const _SubjectFormSheet({
    required this.availableSemesters,
    required this.defaultSemesterId,
  });

  final List<Semester> availableSemesters;
  final String? defaultSemesterId;

  @override
  State<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends State<_SubjectFormSheet> {
  final _name = TextEditingController();
  String _color = '#A23B5C';
  String? _semesterId;

  // Inline semester section state — used when no semesters exist
  final _semesterName = TextEditingController();
  DateTime _semesterStart = DateTime.now();
  DateTime _semesterEnd = DateTime.now().add(const Duration(days: 120));

  bool get _needsInlineSemester => widget.availableSemesters.isEmpty;

  @override
  void initState() {
    super.initState();
    _semesterId = widget.defaultSemesterId;
  }

  @override
  void dispose() {
    _name.dispose();
    _semesterName.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = start ? _semesterStart : _semesterEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _semesterStart = picked;
      } else {
        _semesterEnd = picked;
      }
    });
  }

  void _submit() {
    final subjectName = _name.text.trim();
    if (subjectName.isEmpty) {
      CoreUtils.showNotification(
        message: 'name is required',
        success: false,
        context: context,
      );
      return;
    }

    SemesterCreatePayload? inlineSemester;
    String? semesterIdToUse = _semesterId;

    if (_needsInlineSemester) {
      final termName = _semesterName.text.trim();
      if (termName.isEmpty) {
        CoreUtils.showNotification(
          message: 'term name is required',
          success: false,
          context: context,
        );
        return;
      }
      if (!_semesterStart.isBefore(_semesterEnd)) {
        CoreUtils.showNotification(
          message: 'start date must be before end date',
          success: false,
          context: context,
        );
        return;
      }
      inlineSemester = SemesterCreatePayload(
        name: termName,
        startDate: _semesterStart,
        endDate: _semesterEnd,
      );
      semesterIdToUse = null; // caller resolves after creating the semester
    } else if (semesterIdToUse == null) {
      CoreUtils.showNotification(
        message: 'pick a term to attach this subject to',
        success: false,
        context: context,
      );
      return;
    }

    Navigator.of(context).pop(
      SubjectFormResult(
        subject: SubjectCreatePayload(
          name: subjectName,
          color: _color,
          semesterId: semesterIdToUse ?? '__inline__', // sentinel for caller
        ),
        inlineSemester: inlineSemester,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.sm,
            Spacing.lg,
            Spacing.lg,
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('new subject', style: theme.textTheme.displaySmall),
              ),
              const SizedBox(height: Spacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DefaultTextfield(
                        controller: _name,
                        label: 'subject name',
                        placeholder: 'calculus 101',
                        textInputAction: TextInputAction.next,
                        required: true,
                      ),
                      const SizedBox(height: Spacing.md),
                      Text('color', style: theme.textTheme.labelMedium),
                      const SizedBox(height: Spacing.sm),
                      SubjectColorPicker(
                        selected: _color,
                        onChange: (c) => setState(() => _color = c),
                      ),
                      if (_needsInlineSemester) ...[
                        const SizedBox(height: Spacing.xl),
                        Text(
                          'to organize subjects, group them into a term',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: softInk),
                        ),
                        const SizedBox(height: Spacing.md),
                        DefaultTextfield(
                          controller: _semesterName,
                          label: 'term name',
                          placeholder: 'fall 2026',
                          textInputAction: TextInputAction.next,
                          required: true,
                        ),
                        const SizedBox(height: Spacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _DateCell(
                                label: 'start',
                                value: _semesterStart,
                                onTap: () => _pickDate(start: true),
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: _DateCell(
                                label: 'end',
                                value: _semesterEnd,
                                onTap: () => _pickDate(start: false),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: Spacing.lg),
                        Text('term', style: theme.textTheme.labelMedium),
                        const SizedBox(height: Spacing.sm),
                        _SemesterDropdown(
                          options: widget.availableSemesters,
                          selectedId: _semesterId,
                          onSelect: (id) => setState(() => _semesterId = id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
              DefaultButton(
                title: 'add subject',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: _submit,
              ),
              const SizedBox(height: Spacing.sm),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: softInk),
                child: const Text('cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.xs),
          child: Text(label, style: theme.textTheme.labelMedium),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: InkOpacity.hint)),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    CoreUtils.formatDate(value),
                    style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 16, color: softInk),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SemesterDropdown extends StatelessWidget {
  const _SemesterDropdown({
    required this.options,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Semester> options;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: ink.withValues(alpha: InkOpacity.hint)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          hint: Text(
            'pick a term',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: ink.withValues(alpha: InkOpacity.faint)),
          ),
          items: [
            for (final s in options)
              DropdownMenuItem(
                value: s.id,
                child: Text(s.name.toLowerCase()),
              ),
          ],
          onChanged: (v) {
            if (v != null) onSelect(v);
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/subjects/widgets/subject_form_sheet.dart`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/subjects/widgets/subject_form_sheet.dart
git commit -m "feat(mobile): add SubjectFormSheet with inline semester section

When no semesters exist, the sheet expands to also capture term name +
dates. Caller submits the inlineSemester first, gets the new semester
id back, then submits the subject — atomic from the user's POV. When
semesters already exist, the sheet shows a simple dropdown."
```

---

## Phase 9 — Mobile: SemestersScreen, routing, DI

### Task 37: Build `SemestersScreen` (manager)

**Files:**
- Create: `mobile/lib/src/presentation/modules/study/semesters/screens/semesters_screen.dart`

Manager screen. Top-level route per locked #10. Active pinned at top under `"active"` header; past terms below under `"past terms"` header sorted by `startDate desc`. Floating "+ new term" CTA at the bottom.

- [ ] **Step 1: Write the screen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/delete_semester_sheet.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/semester_card.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/semester_form_sheet.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

class SemestersScreen extends StatefulWidget {
  const SemestersScreen({super.key});

  @override
  State<SemestersScreen> createState() => _SemestersScreenState();
}

class _SemestersScreenState extends State<SemestersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SemestersCubit>().load();
    });
  }

  Future<void> _create(BuildContext context, {required bool noActiveYet}) async {
    final result = await showSemesterFormSheet(context, noActiveYet: noActiveYet);
    if (!context.mounted || result == null || result.create == null) return;
    final cubit = context.read<SemestersCubit>();
    final created = await cubit.create(payload: result.create!);
    if (!context.mounted || created == null) return;
    if (result.makeActive && !created.isActive) {
      await cubit.activate(id: created.id);
    }
    if (!context.mounted) return;
    final msg = result.makeActive
        ? '${created.name.toLowerCase()} is now your active term'
        : '${created.name.toLowerCase()} added';
    CoreUtils.showNotification(message: msg, success: true, context: context);
  }

  Future<void> _edit(BuildContext context, Semester semester) async {
    final result = await showSemesterFormSheet(
      context,
      editing: semester,
      noActiveYet: false,
    );
    if (!context.mounted || result == null || result.update == null) return;
    final cubit = context.read<SemestersCubit>();
    await cubit.update(id: semester.id, payload: result.update!);
  }

  Future<void> _delete(BuildContext context, Semester semester, {required bool isActive}) async {
    final ok = await showDeleteSemesterSheet(
      context,
      semester: semester,
      isActive: isActive,
    );
    if (!context.mounted || !ok) return;
    // Re-fetch stats so the toast can report orphaned count accurately.
    // Cubit.delete returned ok = true, but it doesn't expose the count.
    // For v1, use a generic preserved-as-ad-hoc message.
    CoreUtils.showNotification(
      message: 'sessions preserved as ad-hoc activities',
      success: true,
      context: context,
    );
  }

  Future<void> _activate(BuildContext context, Semester semester) async {
    final cubit = context.read<SemestersCubit>();
    final ok = await cubit.activate(id: semester.id);
    if (!context.mounted || !ok) return;
    CoreUtils.showNotification(
      message: '${semester.name.toLowerCase()} is now active',
      success: true,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return Scaffold(
      appBar: const MainAppBar(title: 'terms'),
      body: BlocConsumer<SemestersCubit, SemestersState>(
        listenWhen: (prev, next) =>
            next is SemestersLoaded && next.mutationError != null,
        listener: (context, state) {
          if (state is SemestersLoaded && state.mutationError != null) {
            CoreUtils.showNotification(
              message: state.mutationError!,
              success: false,
              context: context,
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            SemestersInitial() || SemestersLoading() => Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            SemestersError(:final errorMessage) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Text(
                    errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(color: softInk),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SemestersLoaded(:final semesters, :final activeSemester) =>
              _LoadedBody(
                semesters: semesters,
                active: activeSemester,
                onCreate: () =>
                    _create(context, noActiveYet: activeSemester == null),
                onEdit: (s) => _edit(context, s),
                onDelete: (s) => _delete(
                  context,
                  s,
                  isActive: activeSemester?.id == s.id,
                ),
                onActivate: (s) => _activate(context, s),
              ),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.semesters,
    required this.active,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    required this.onActivate,
  });

  final List<Semester> semesters;
  final Semester? active;
  final VoidCallback onCreate;
  final ValueChanged<Semester> onEdit;
  final ValueChanged<Semester> onDelete;
  final ValueChanged<Semester> onActivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    if (semesters.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.lg),
              Text(
                'no terms yet',
                style: theme.textTheme.displaySmall,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'add one to start grouping subjects.',
                style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
              ),
              const Spacer(),
              DefaultButton(
                title: 'add a term',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: onCreate,
              ),
              const SizedBox(height: Spacing.lg),
            ],
          ),
        ),
      );
    }

    final pastTerms = semesters
        .where((s) => active == null || s.id != active!.id)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.sm,
                Spacing.lg,
                Spacing.lg,
              ),
              children: [
                if (active != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Text(
                      'active',
                      style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                    ),
                  ),
                  SemesterCard(
                    semester: active!,
                    isActive: true,
                    onActivate: () {}, // already active
                    onAction: (a) => switch (a) {
                      SemesterCardAction.edit => onEdit(active!),
                      SemesterCardAction.delete => onDelete(active!),
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                ],
                if (pastTerms.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: Text(
                      'past terms',
                      style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                    ),
                  ),
                  for (final s in pastTerms) ...[
                    SemesterCard(
                      semester: s,
                      isActive: false,
                      onActivate: () => onActivate(s),
                      onAction: (a) => switch (a) {
                        SemesterCardAction.edit => onEdit(s),
                        SemesterCardAction.delete => onDelete(s),
                      },
                    ),
                    const SizedBox(height: Spacing.sm),
                  ],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.lg,
            ),
            child: DefaultButton(
              title: 'add a term',
              fullWidth: true,
              size: ButtonSize.large,
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/semesters/screens/semesters_screen.dart`
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/semesters/screens/semesters_screen.dart
git commit -m "feat(mobile): add SemestersScreen manager

'active' section pinned top, 'past terms' below sorted by startDate desc.
Tap a non-active card to activate. Overflow menu offers edit + delete
via the existing sheets. Sticky 'add a term' CTA at the bottom."
```

### Task 38: Register `SemestersCubit` in DI + providers + router

**Files:**
- Modify: `mobile/lib/core/utils/injection_container.dart`
- Modify: `mobile/lib/main.dart`
- Modify: `mobile/lib/core/utils/router.dart`

- [ ] **Step 1: Register the cubit in `injection_container.dart`**

After the `// MARK: subjects-cubits-end` line, add:

```dart
  // MARK: semesters-cubits-start
  sl.registerFactory(
    () => SemestersCubit(semesterRepository: sl<ISemesterRepository>()),
  );
  // MARK: semesters-cubits-end
```

Add the import at the top of the file:

```dart
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
```

- [ ] **Step 2: Register the cubit in `main.dart`**

In the `MultiBlocProvider` providers list, after the `// MARK: subjects-providers-end` line, add:

```dart
        // MARK: semesters-providers-start
        BlocProvider(create: (_) => sl<SemestersCubit>()),
        // MARK: semesters-providers-end
```

Add the import:

```dart
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
```

- [ ] **Step 3: Add `/semesters` top-level route in `router.dart`**

Add the import at the top:

```dart
import 'package:study_time_tracker/src/presentation/modules/study/semesters/screens/semesters_screen.dart';
```

In the `GoRouter` `routes` list, add this route BEFORE the `StatefulShellRoute.indexedStack` (so it's outside the shell — bottom nav doesn't show on this route):

```dart
        GoRoute(
          path: '/semesters',
          pageBuilder: (_, state) =>
              _page(const SemestersScreen(), state.pageKey),
        ),
```

- [ ] **Step 4: Run analyze**

Run from `mobile/`: `flutter analyze`
Expected: SemestersCubit, route, and provider call sites are clean. Remaining errors are dashboard / subjects screen integration (Phase 10).

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/core/utils/injection_container.dart \
        mobile/lib/main.dart \
        mobile/lib/core/utils/router.dart
git commit -m "feat(mobile): wire SemestersCubit + /semesters route

Cubit registered in get_it under semesters-cubits-* MARK block and in
MultiBlocProvider under semesters-providers-*. Route is top-level
(outside StatefulShellRoute) so the bottom nav pill hides while
managing semesters."
```

### Task 39: Shell-level `BlocListener` for active-semester change

**Files:**
- Modify: `mobile/lib/src/presentation/modules/study/shell/screens/study_shell_screen.dart`

Per locked decision #12, when the active semester id changes, the shell calls `SubjectsCubit.loadForSemester(newId)`. The shell wraps its body in a `BlocListener<SemestersCubit, SemestersState>` that watches `activeSemester?.id`.

- [ ] **Step 1: Read the existing shell file**

Run from `mobile/`: open `lib/src/presentation/modules/study/shell/screens/study_shell_screen.dart` and identify the build method's root widget.

- [ ] **Step 2: Wrap the body in a multi-listener**

At the top of the file, add imports if not already present:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
```

Wrap the existing `Scaffold` (or whatever the shell's root is) inside a `MultiBlocListener`:

```dart
return MultiBlocListener(
  listeners: [
    BlocListener<SemestersCubit, SemestersState>(
      listenWhen: (prev, next) {
        final prevId = prev is SemestersLoaded ? prev.activeSemesterId : null;
        final nextId = next is SemestersLoaded ? next.activeSemesterId : null;
        return prevId != nextId;
      },
      listener: (context, state) {
        if (state is SemestersLoaded) {
          context.read<SubjectsCubit>().loadForSemester(state.activeSemesterId);
        }
      },
    ),
  ],
  child: /* existing Scaffold */,
);
```

Also kick off `SemestersCubit.load()` in `initState` if not already:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<SemestersCubit>().load();
  });
}
```

- [ ] **Step 3: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/shell/`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/shell/screens/study_shell_screen.dart
git commit -m "feat(mobile): shell-level BlocListener bridges SemestersCubit and SubjectsCubit

When the active semester id changes (initial load or activate), the shell
calls SubjectsCubit.loadForSemester(newId). The two cubits stay decoupled.
Shell also kicks off SemestersCubit.load() on mount so the pill is
populated before the dashboard reads it."
```

---

## Phase 10 — Mobile: dashboard + subjects screen integration

### Task 40: Update `DashboardScreen` for pill + ad-hoc + drop no-semester body

**Files:**
- Modify: `mobile/lib/src/presentation/modules/study/dashboard/screens/dashboard_screen.dart`

Big changes here. The dashboard now:
1. Reads `SemestersCubit` to render the pill in the app bar title slot (hidden when no semesters).
2. Removes the `SubjectsNoSemesters` empty body — fresh users go straight to the normal layout with just the ad-hoc chip.
3. Wires `SubjectSelector`'s new `onSelectAdHoc` callback.
4. Wires `SessionTile`'s new ad-hoc input mode and ad-hoc start.
5. Adds an `"other"` aggregate row at the bottom of `_SubjectTotalsList` when ad-hoc time > 0.

- [ ] **Step 1: Replace `dashboard_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/analytics/analytics_summary.dart';
import 'package:study_time_tracker/src/domain/models/session/study_session.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/presentation/modules/authentication/services/authentication_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/active_session_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/widgets/session_tile.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/widgets/subject_selector.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/pulp_tile.dart';

enum _HomeMenuAction { signOut }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _pickedSubjectId;
  bool _adHocMode = false;
  late final TextEditingController _adHocController;

  @override
  void initState() {
    super.initState();
    _adHocController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActiveSessionCubit>().checkActive();
      context.read<DashboardStatsCubit>().load();
    });
  }

  @override
  void dispose() {
    _adHocController.dispose();
    super.dispose();
  }

  Subject? _resolveSubject(SubjectsState subjectsState, String id) {
    if (subjectsState is! SubjectsLoaded) return null;
    for (final s in subjectsState.subjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _pickSubject(Subject subject) {
    setState(() {
      _pickedSubjectId = subject.id;
      _adHocMode = false;
    });
  }

  void _selectAdHoc() {
    setState(() {
      // Toggle off if already in ad-hoc mode (re-tap exits)
      if (_adHocMode) {
        _adHocMode = false;
        _adHocController.clear();
      } else {
        _adHocMode = true;
        _pickedSubjectId = null;
      }
    });
  }

  Future<void> _start(BuildContext context) async {
    if (_adHocMode) {
      final activity = _adHocController.text.trim();
      if (activity.isEmpty) return;
      await context.read<ActiveSessionCubit>().startAdHoc(activityName: activity);
    } else if (_pickedSubjectId != null) {
      await context.read<ActiveSessionCubit>().start(subjectId: _pickedSubjectId!);
    }
  }

  Future<void> _pause(BuildContext context) async {
    await context.read<ActiveSessionCubit>().pause();
  }

  Future<void> _resume(BuildContext context) async {
    await context.read<ActiveSessionCubit>().resume();
  }

  Future<void> _stop(BuildContext context) async {
    final cubit = context.read<ActiveSessionCubit>();
    final completed = await cubit.stop();
    if (!context.mounted || completed == null) return;
    context.read<DashboardStatsCubit>().load();
    final mins = ((completed.effectiveStudyTime ?? 0) / 60).round();
    CoreUtils.showNotification(
      message: mins > 0 ? 'nice — $mins min logged' : 'session saved',
      success: true,
      context: context,
    );
    setState(() {
      _pickedSubjectId = null;
      _adHocMode = false;
      _adHocController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: '',
        titleWidget: BlocBuilder<SemestersCubit, SemestersState>(
          builder: (context, state) {
            if (state is! SemestersLoaded) return const SizedBox.shrink();
            final active = state.activeSemester;
            if (active == null) return const SizedBox.shrink();
            return ActiveSemesterPill(semester: active);
          },
        ),
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'more',
            position: PopupMenuPosition.under,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            onSelected: (action) {
              switch (action) {
                case _HomeMenuAction.signOut:
                  context.read<AuthenticationCubit>().logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _HomeMenuAction.signOut,
                child: Text('sign out'),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ActiveSessionCubit, ActiveSessionState>(
        listenWhen: (prev, next) {
          final prevErr = _mutationErrorOf(prev);
          final nextErr = _mutationErrorOf(next);
          return nextErr != null && nextErr != prevErr;
        },
        listener: (context, state) {
          final err = _mutationErrorOf(state);
          if (err != null) {
            CoreUtils.showNotification(
              message: err,
              success: false,
              context: context,
            );
          }
        },
        builder: (context, sessionState) {
          return BlocBuilder<SubjectsCubit, SubjectsState>(
            builder: (context, subjectsState) {
              return _Body(
                sessionState: sessionState,
                subjectsState: subjectsState,
                pickedSubjectId: _pickedSubjectId,
                adHocMode: _adHocMode,
                adHocController: _adHocController,
                onPickSubject: _pickSubject,
                onSelectAdHoc: _selectAdHoc,
                onStart: () => _start(context),
                onPause: () => _pause(context),
                onResume: () => _resume(context),
                onStop: () => _stop(context),
                onActivityChanged: (_) => setState(() {}),
                resolveSubject: (id) => _resolveSubject(subjectsState, id),
              );
            },
          );
        },
      ),
    );
  }

  String? _mutationErrorOf(ActiveSessionState state) {
    return switch (state) {
      ActiveSessionIdle(:final mutationError) => mutationError,
      ActiveSessionRunning(:final mutationError) => mutationError,
      ActiveSessionPaused(:final mutationError) => mutationError,
      ActiveSessionError(:final errorMessage) => errorMessage,
      _ => null,
    };
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.sessionState,
    required this.subjectsState,
    required this.pickedSubjectId,
    required this.adHocMode,
    required this.adHocController,
    required this.onPickSubject,
    required this.onSelectAdHoc,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onActivityChanged,
    required this.resolveSubject,
  });

  final ActiveSessionState sessionState;
  final SubjectsState subjectsState;
  final String? pickedSubjectId;
  final bool adHocMode;
  final TextEditingController adHocController;
  final ValueChanged<Subject> onPickSubject;
  final VoidCallback onSelectAdHoc;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final ValueChanged<String> onActivityChanged;
  final Subject? Function(String id) resolveSubject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sessionState is ActiveSessionChecking ||
        sessionState is ActiveSessionInitial) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
    if (sessionState is ActiveSessionError) {
      return _ErrorBody(
        message: (sessionState as ActiveSessionError).errorMessage,
        onRetry: () => context.read<ActiveSessionCubit>().checkActive(),
      );
    }

    final subjects = subjectsState is SubjectsLoaded
        ? (subjectsState as SubjectsLoaded).subjects
        : const <Subject>[];

    final activeSession = switch (sessionState) {
      ActiveSessionRunning(:final session) => session,
      ActiveSessionPaused(:final session) => session,
      _ => null,
    };
    final activeSubject = activeSession == null || activeSession.subjectId == null
        ? null
        : resolveSubject(activeSession.subjectId!);
    final pickedSubject = pickedSubjectId == null
        ? null
        : resolveSubject(pickedSubjectId!);

    final todaySeconds = _todaySecondsOf(sessionState);
    final todaySubjectCount = _todaySubjectCountOf(sessionState);
    final mutating = _mutatingOf(sessionState);
    final isPaused = sessionState is ActiveSessionPaused;
    final isActive =
        sessionState is ActiveSessionRunning || sessionState is ActiveSessionPaused;

    final startEnabled = !mutating &&
        !isActive &&
        (adHocMode
            ? adHocController.text.trim().isNotEmpty
            : pickedSubjectId != null);

    final bottomNavReserve = 56 +
        Spacing.md +
        MediaQuery.viewPaddingOf(context).bottom +
        Spacing.md;

    return SafeArea(
      top: false,
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.sm,
          Spacing.lg,
          bottomNavReserve,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Greeting(),
            const SizedBox(height: Spacing.lg),
            SessionTile(
              activeSession: activeSession,
              activeSubject: activeSubject,
              pickedSubject: pickedSubject,
              adHocMode: adHocMode,
              adHocController: adHocController,
              isPaused: isPaused,
              mutating: mutating,
              onStart: startEnabled ? onStart : null,
              onPause: onPause,
              onResume: onResume,
              onStop: onStop,
              onActivityChanged: onActivityChanged,
            ),
            const SizedBox(height: Spacing.md),
            _StatTilesRow(
              todaySeconds: todaySeconds,
              todaySubjectCount: todaySubjectCount,
            ),
            const SizedBox(height: Spacing.lg),
            if (!isActive)
              _SubjectPickerSection(
                subjects: subjects,
                selectedId: pickedSubjectId,
                adHocSelected: adHocMode,
                onSelect: onPickSubject,
                onSelectAdHoc: onSelectAdHoc,
              ),
            if (isActive) const _SubjectTotalsList(),
          ],
        ),
      ),
    );
  }

  static int _todaySecondsOf(ActiveSessionState s) => switch (s) {
        ActiveSessionIdle(:final todaySeconds) => todaySeconds,
        ActiveSessionRunning(:final todaySeconds) => todaySeconds,
        ActiveSessionPaused(:final todaySeconds) => todaySeconds,
        _ => 0,
      };

  static int _todaySubjectCountOf(ActiveSessionState s) => switch (s) {
        ActiveSessionIdle(:final todaySubjectCount) => todaySubjectCount,
        ActiveSessionRunning(:final todaySubjectCount) => todaySubjectCount,
        ActiveSessionPaused(:final todaySubjectCount) => todaySubjectCount,
        _ => 0,
      };

  static bool _mutatingOf(ActiveSessionState s) => switch (s) {
        ActiveSessionIdle(:final mutating) => mutating,
        ActiveSessionRunning(:final mutating) => mutating,
        ActiveSessionPaused(:final mutating) => mutating,
        _ => false,
      };
}

// =============================================================================
// Greeting
// =============================================================================

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);
    final greeting = _timeOfDayGreeting(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$greeting.', style: theme.textTheme.displayMedium),
        const SizedBox(height: Spacing.xs),
        BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
          builder: (context, state) {
            final streak = state is DashboardStatsLoaded ? state.streakDays : 0;
            final loading = state is DashboardStatsInitial ||
                state is DashboardStatsLoading;
            return Text(
              _streakLine(streak, loading: loading),
              style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
            );
          },
        ),
      ],
    );
  }

  String _timeOfDayGreeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'good morning';
    if (h < 18) return 'good afternoon';
    return 'good evening';
  }

  String _streakLine(int streak, {required bool loading}) {
    if (loading) return '…';
    if (streak == 0) return 'no streak yet — start your first session.';
    if (streak == 1) return 'day one. today is the day to make it two.';
    final next = streak + 1;
    return "on a $streak-day streak. today's the day to make it $next.";
  }
}

class _StatTilesRow extends StatelessWidget {
  const _StatTilesRow({
    required this.todaySeconds,
    required this.todaySubjectCount,
  });

  final int todaySeconds;
  final int todaySubjectCount;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
      builder: (context, state) {
        final loaded = state is DashboardStatsLoaded ? state : null;
        return Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'today total',
                value: CoreUtils.formatHm(todaySeconds, dashOnZero: true),
                caption: _todayCaption(todaySubjectCount),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: _StatTile(
                label: '7-day window',
                value: CoreUtils.formatHm(loaded?.windowSeconds ?? 0, dashOnZero: true),
                caption: _windowCaption(loaded),
              ),
            ),
          ],
        );
      },
    );
  }

  String _todayCaption(int subjects) {
    if (todaySeconds == 0) return 'no sessions yet';
    if (subjects <= 1) return 'across 1 focus area';
    return 'across $subjects focus areas';
  }

  String _windowCaption(DashboardStatsLoaded? loaded) {
    if (loaded == null) return '…';
    final window = loaded.windowSeconds;
    final best = loaded.bestWindowSeconds;
    if (window == 0) return 'no sessions yet this week';
    if (best <= window) return 'your best 7-day window';
    final percent = (((best - window) / best) * 100).round();
    return '$percent% under your best';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return PulpTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: softInk)),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineLarge?.copyWith(height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            caption,
            style: theme.textTheme.labelSmall?.copyWith(color: softInk),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SubjectTotalsList extends StatelessWidget {
  const _SubjectTotalsList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = theme.colorScheme.onSurface;
    final softInk = ink.withValues(alpha: InkOpacity.soft);

    return BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
      builder: (context, state) {
        if (state is! DashboardStatsLoaded) return const SizedBox.shrink();
        final stats = state.subjectStats.where((s) => s.totalTime > 0).toList();
        // Ad-hoc time: walk the recent sessions list in DashboardStatsLoaded
        // for sessions with no subjectId. If DashboardStatsLoaded doesn't
        // expose ad-hoc totals yet, add them when the analytics endpoint
        // returns them (TASK note in next phase).
        final adHocSeconds = state.adHocSeconds; // see Task 42
        if (stats.isEmpty && adHocSeconds == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('your subjects',
                style: theme.textTheme.labelSmall?.copyWith(color: softInk)),
            const SizedBox(height: Spacing.sm),
            for (var i = 0; i < stats.length; i++) ...[
              _SubjectTotalRow(stat: stats[i], brightness: brightness),
              if (i < stats.length - 1 || adHocSeconds > 0)
                Divider(
                  color: ink.withValues(alpha: 0.08),
                  height: 1,
                  thickness: 1,
                ),
            ],
            if (adHocSeconds > 0)
              _OtherRow(totalSeconds: adHocSeconds),
          ],
        );
      },
    );
  }
}

class _SubjectTotalRow extends StatelessWidget {
  const _SubjectTotalRow({required this.stat, required this.brightness});

  final SubjectStat stat;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<SubjectsCubit, SubjectsState>(
      buildWhen: (a, b) => a.runtimeType != b.runtimeType,
      builder: (context, subjectsState) {
        final color = _colorForSubject(subjectsState).resolve(brightness);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.md),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  stat.subjectName,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CoreUtils.formatHm(stat.totalTime, dashOnZero: false),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: InkOpacity.soft),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SubjectColor _colorForSubject(SubjectsState subjectsState) {
    if (subjectsState is SubjectsLoaded) {
      for (final s in subjectsState.subjects) {
        if (s.id == stat.subjectId) return SubjectColor.fromHex(s.color);
      }
    }
    return SubjectColor.risoFig;
  }
}

class _OtherRow extends StatelessWidget {
  const _OtherRow({required this.totalSeconds});

  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          const SizedBox(width: 14), // align with subject color square
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text('other', style: theme.textTheme.bodyLarge),
          ),
          Text(
            CoreUtils.formatHm(totalSeconds, dashOnZero: false),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: ink.withValues(alpha: InkOpacity.soft),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectPickerSection extends StatelessWidget {
  const _SubjectPickerSection({
    required this.subjects,
    required this.selectedId,
    required this.adHocSelected,
    required this.onSelect,
    required this.onSelectAdHoc,
  });

  final List<Subject> subjects;
  final String? selectedId;
  final bool adHocSelected;
  final ValueChanged<Subject> onSelect;
  final VoidCallback onSelectAdHoc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('your subjects',
            style: theme.textTheme.labelSmall?.copyWith(color: softInk)),
        const SizedBox(height: Spacing.sm),
        SubjectSelector(
          subjects: subjects,
          selectedId: selectedId,
          adHocSelected: adHocSelected,
          onSelect: onSelect,
          onSelectAdHoc: onSelectAdHoc,
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              const SizedBox(height: Spacing.md),
              Text('something went wrong',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: Spacing.xs),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: InkOpacity.soft),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.lg),
              TextButton(
                onPressed: onRetry,
                child: const Text('try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Note: this references `state.adHocSeconds` on `DashboardStatsLoaded` — that field is added in Task 42 below. If you want to ship Dashboard before that, temporarily replace with `final adHocSeconds = 0;` and remove the import dependency. Otherwise Task 42 fills it in.

- [ ] **Step 2: Update `MainAppBar` to accept a custom title widget**

Modify `mobile/lib/src/presentation/widgets/app_bar.dart` to support an optional `titleWidget` parameter that takes precedence over the string title. Replace the file:

```dart
import 'package:flutter/material.dart';
import 'package:study_time_tracker/core/configs/themes.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
  });

  final String title;

  /// Overrides the [title] string with an arbitrary widget. Used by the
  /// dashboard to slot in the ActiveSemesterPill conditionally.
  final Widget? titleWidget;

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ??
          Text(
            title,
            style: TextStyle(
              fontFamily: kFontFraunces,
              fontStyle: FontStyle.italic,
              fontSize: 22,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
      actions: actions,
    );
  }
}
```

- [ ] **Step 3: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/study/dashboard/screens/dashboard_screen.dart`
Expected: clean (modulo the `adHocSeconds` reference if Task 42 isn't done yet — apply the workaround if so).

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/dashboard/screens/dashboard_screen.dart \
        mobile/lib/src/presentation/widgets/app_bar.dart
git commit -m "feat(mobile): dashboard pill + ad-hoc start + 'other' totals row

Pill renders only when SemestersCubit has an active semester. Ad-hoc
chip in the picker switches SessionTile into inline-input mode and wires
ActiveSessionCubit.startAdHoc. _SubjectTotalsList grows an 'other'
aggregate row at the bottom when adHocSeconds > 0. MainAppBar gains an
optional titleWidget slot for the pill."
```

### Task 41: Update `SubjectsListScreen` to use the pill + sheet flow

**Files:**
- Modify: `mobile/lib/src/presentation/modules/subjects/screens/subjects_list_screen.dart`

Removes the legacy `_NoSemesterBody` inline form and routes subject creation through `showSubjectFormSheet`. The app bar title becomes the pill when `1+ semesters exist`, otherwise falls back to `"subjects"` Fraunces-italic.

- [ ] **Step 1: Replace the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:study_time_tracker/core/configs/themes.dart';
import 'package:study_time_tracker/core/utils/core_utils.dart';
import 'package:study_time_tracker/src/domain/models/semester/semester_payload.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject.dart';
import 'package:study_time_tracker/src/domain/models/subject/subject_payload.dart';
import 'package:study_time_tracker/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/services/semesters_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/study/semesters/widgets/active_semester_pill.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/services/subjects_cubit.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_form_sheet.dart';
import 'package:study_time_tracker/src/presentation/modules/subjects/widgets/subject_tile.dart';
import 'package:study_time_tracker/src/presentation/widgets/app_bar.dart';
import 'package:study_time_tracker/src/presentation/widgets/default_button.dart';

class SubjectsListScreen extends StatefulWidget {
  const SubjectsListScreen({super.key});

  @override
  State<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends State<SubjectsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stats = context.read<DashboardStatsCubit>();
      if (stats.state is DashboardStatsInitial) {
        stats.load();
      }
    });
  }

  Future<void> _onAddSubject(BuildContext context) async {
    final semestersState = context.read<SemestersCubit>().state;
    final availableSemesters = semestersState is SemestersLoaded
        ? semestersState.semesters
        : <Semester>[];
    final defaultSemesterId = semestersState is SemestersLoaded
        ? semestersState.activeSemesterId
        : null;

    final result = await showSubjectFormSheet(
      context,
      availableSemesters: availableSemesters,
      defaultSemesterId: defaultSemesterId,
    );
    if (!context.mounted || result == null) return;

    String semesterId;
    if (result.inlineSemester != null) {
      // Create the inline semester first
      final newSemester = await context
          .read<SemestersCubit>()
          .create(payload: result.inlineSemester!);
      if (!context.mounted || newSemester == null) return;
      // First semester auto-activates if no other is active
      if (!newSemester.isActive) {
        await context.read<SemestersCubit>().activate(id: newSemester.id);
      }
      semesterId = newSemester.id;
    } else {
      semesterId = result.subject.semesterId;
    }

    final ok = await context.read<SubjectsCubit>().createSubject(
          payload: SubjectCreatePayload(
            name: result.subject.name,
            color: result.subject.color,
            semesterId: semesterId,
          ),
        );
    if (!context.mounted) return;
    if (ok) {
      CoreUtils.showNotification(
        message: '${result.subject.name.toLowerCase()} added',
        success: true,
        context: context,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Subject subject) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        title: Text('delete ${subject.name.toLowerCase()}?',
            style: theme.textTheme.titleLarge),
        content: Text(
          'sessions for this subject will be preserved as ad-hoc activities.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cubit = context.read<SubjectsCubit>();
    final ok = await cubit.deleteSubject(id: subject.id);
    if (!ok && context.mounted) {
      final s = cubit.state;
      final msg = s is SubjectsLoaded ? s.mutationError : null;
      if (msg != null) {
        CoreUtils.showNotification(message: msg, success: false, context: context);
      }
    } else if (ok && context.mounted) {
      CoreUtils.showNotification(
        message: 'sessions preserved as ad-hoc activities',
        success: true,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        title: 'subjects',
        titleWidget: BlocBuilder<SemestersCubit, SemestersState>(
          builder: (context, state) {
            if (state is! SemestersLoaded) return const SizedBox.shrink();
            final active = state.activeSemester;
            if (active == null) return const SizedBox.shrink();
            return ActiveSemesterPill(semester: active);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'add subject',
            onPressed: () => _onAddSubject(context),
          ),
        ],
      ),
      body: BlocConsumer<SubjectsCubit, SubjectsState>(
        listenWhen: (prev, next) =>
            next is SubjectsLoaded && next.mutationError != null,
        listener: (context, state) {
          if (state is SubjectsLoaded && state.mutationError != null) {
            CoreUtils.showNotification(
              message: state.mutationError!,
              success: false,
              context: context,
            );
          }
        },
        builder: (context, state) {
          return switch (state) {
            SubjectsInitial() || SubjectsLoading() => Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            SubjectsError(:final errorMessage) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SubjectsLoaded() => _LoadedBody(
                state: state,
                onAdd: () => _onAddSubject(context),
                onEdit: (s) => context.push('/subjects/${s.id}'),
                onDelete: _confirmDelete,
              ),
          };
        },
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final SubjectsLoaded state;
  final VoidCallback onAdd;
  final ValueChanged<Subject> onEdit;
  final void Function(BuildContext, Subject) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final softInk = theme.colorScheme.onSurface
        .withValues(alpha: InkOpacity.soft);
    final bottomReserve = _bottomNavReserve(context);

    if (state.subjects.isEmpty) {
      return SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.lg,
            Spacing.lg,
            Spacing.lg,
            bottomReserve,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Spacing.md),
              Text("you haven't added any subjects yet",
                  style: theme.textTheme.displaySmall),
              const SizedBox(height: Spacing.xs),
              Text(
                'pick a color, name your subject, and start tracking.',
                style: theme.textTheme.bodyLarge?.copyWith(color: softInk),
              ),
              const SizedBox(height: Spacing.xl),
              DefaultButton(
                title: 'add your first subject',
                fullWidth: true,
                size: ButtonSize.large,
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final sub = context.read<SubjectsCubit>();
        final stats = context.read<DashboardStatsCubit>();
        await sub.loadForSemester(state.semesterId);
        if (context.mounted) await stats.load();
      },
      color: theme.colorScheme.primary,
      child: BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
        builder: (context, statsState) {
          final loadingStats = statsState is DashboardStatsInitial ||
              statsState is DashboardStatsLoading;
          final totalsBySubject = <String, int>{
            if (statsState is DashboardStatsLoaded)
              for (final s in statsState.subjectStats) s.subjectId: s.totalTime,
          };
          final count = state.subjects.length;
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              bottomReserve,
            ),
            itemCount: state.subjects.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.xs,
                    bottom: Spacing.xs,
                  ),
                  child: Text(
                    count == 1 ? '1 subject' : '$count subjects',
                    style: theme.textTheme.labelSmall?.copyWith(color: softInk),
                  ),
                );
              }
              final subject = state.subjects[index - 1];
              return SubjectTile(
                subject: subject,
                semester: null,
                totalSeconds: totalsBySubject[subject.id],
                loadingTotal: loadingStats,
                onTap: () => onEdit(subject),
                onDelete: () => onDelete(context, subject),
              );
            },
          );
        },
      ),
    );
  }
}

double _bottomNavReserve(BuildContext context) {
  return 56 +
      Spacing.md +
      MediaQuery.viewPaddingOf(context).bottom +
      Spacing.md;
}
```

Note: `SubjectTile` previously took a `semester` argument and showed its name. Under the new model, the active term context is shown by the pill in the app bar instead. Pass `semester: null` for now; if the existing `SubjectTile` requires non-null, modify its signature to accept null and hide the semester chip when null.

- [ ] **Step 2: Run analyze**

Run from `mobile/`: `flutter analyze lib/src/presentation/modules/subjects/`
Expected: clean except possibly `SubjectTile` (patch its signature if needed). The legacy `subject_form_screen.dart` may still exist — leave it for now (Task 43 handles cleanup).

- [ ] **Step 3: Commit**

```bash
git add mobile/lib/src/presentation/modules/subjects/screens/subjects_list_screen.dart \
        mobile/lib/src/presentation/modules/subjects/widgets/subject_tile.dart
git commit -m "feat(mobile): subjects screen uses pill + new sheet flow

Drops the legacy _NoSemesterBody inline form (replaced by the sheet's
inline two-section behavior). Pill renders in the title slot when 1+
semesters exist; fallback Fraunces-italic 'subjects' otherwise.
SubjectTile no longer requires a non-null semester."
```

### Task 42: Add `adHocSeconds` to `DashboardStatsLoaded`

**Files:**
- Modify: `mobile/lib/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart`

The "other" aggregate row needs total ad-hoc seconds for the period. Two options for sourcing it:
1. Compute locally in the cubit by walking the recent sessions list (cheapest, no API change).
2. Add a backend field (e.g., extend the analytics summary endpoint).

Go with option 1 for v1 — the dashboard already calls `getAll()` on sessions for the today totals computation; we add a per-period ad-hoc sum in the same pass.

- [ ] **Step 1: Inspect the existing cubit**

Run from `mobile/`: open `lib/src/presentation/modules/study/dashboard/services/dashboard_stats_cubit.dart` and find the `DashboardStatsLoaded` state class definition (in the partner `dashboard_stats_state.dart` if split). Add an `adHocSeconds` field.

```dart
class DashboardStatsLoaded extends DashboardStatsState {
  const DashboardStatsLoaded({
    required this.streakDays,
    required this.windowSeconds,
    required this.bestWindowSeconds,
    required this.subjectStats,
    required this.adHocSeconds,
  });

  final int streakDays;
  final int windowSeconds;
  final int bestWindowSeconds;
  final List<SubjectStat> subjectStats;
  final int adHocSeconds;

  @override
  List<Object?> get props =>
      [streakDays, windowSeconds, bestWindowSeconds, subjectStats, adHocSeconds];
}
```

- [ ] **Step 2: Populate it in the cubit's `load()`**

In the cubit body, where the analytics response is processed, compute `adHocSeconds`. If the existing implementation reads from `analyticsRepository.getSummary()` and the API response doesn't expose ad-hoc time, fall back to walking the sessions list:

```dart
Future<int> _computeAdHocSeconds() async {
  final response = await sessionRepository.getAll();
  if (!response.success) return 0;
  // Window matches the existing 7-day analytics window.
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  var total = 0;
  for (final s in response.data) {
    if (s.status != SessionStatus.completed) continue;
    if (s.subjectId != null) continue; // not ad-hoc
    if (s.startTime.isBefore(cutoff)) continue;
    total += s.effectiveStudyTime ?? 0;
  }
  return total;
}
```

Then update `load()` to pass `adHocSeconds:` into `DashboardStatsLoaded`. You'll need to inject `ISessionRepository` if the cubit doesn't already have it — update DI accordingly.

Note: passing `ISessionRepository` into a stats cubit is a small layer-bend. Cleaner long-term is to extend the analytics endpoint, but that's a follow-up. For v1 this trade-off is acceptable.

- [ ] **Step 3: Run analyze + the existing cubit test if there is one**

Run from `mobile/`: `flutter analyze && flutter test`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/src/presentation/modules/study/dashboard/services/ \
        mobile/lib/core/utils/injection_container.dart
git commit -m "feat(mobile): DashboardStatsLoaded.adHocSeconds for the 'other' totals row

Computed in DashboardStatsCubit by summing 7-day completed sessions with
no subjectId. Backend-level aggregation is a follow-up — this avoids an
API change for v1."
```

### Task 43: Remove the legacy `subject_form_screen.dart` (if no longer used)

**Files:**
- Modify or delete: `mobile/lib/src/presentation/modules/subjects/screens/subject_form_screen.dart`
- Modify: `mobile/lib/core/utils/router.dart`

The `/subjects/new` and `/subjects/:id` routes previously pushed `SubjectFormScreen`. With the sheet flow, the `new` route is unused (the list screen opens the sheet directly). The edit route may still be used by `_LoadedBody.onEdit`.

Decision for v1: keep `SubjectFormScreen` *only* for the edit route. Update its constructor to require an `id` and remove any code paths that handle creation. Or: rewrite the edit flow to also open the sheet in edit mode (similar pattern to semester edit). For minimum surface area, keep it.

- [ ] **Step 1: Check call sites**

Run from `mobile/`: `grep -rn "SubjectFormScreen" lib/`
Expected: `router.dart` has the two routes. `subjects_list_screen.dart` calls `context.push('/subjects/${subject.id}')` for edits.

- [ ] **Step 2: Remove the `new` route**

Modify `lib/core/utils/router.dart`. Find the `subjects-routes-start` block and remove the `path: 'new'` sub-route. Keep the `path: ':id'` sub-route.

- [ ] **Step 3: Run analyze**

Run from `mobile/`: `flutter analyze`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/core/utils/router.dart
git commit -m "chore(mobile): drop /subjects/new route — sheet replaces it

Subject creation goes through showSubjectFormSheet now. Subject edit
still uses the legacy /subjects/:id route + SubjectFormScreen for v1.
Edit-via-sheet is a follow-up."
```

---

## Phase 11 — Polish + end-to-end smoke

### Task 44: Run full mobile test + analyze

- [ ] **Step 1: Analyze**

Run from `mobile/`: `flutter analyze`
Expected: zero issues.

- [ ] **Step 2: Test**

Run from `mobile/`: `flutter test`
Expected: all tests pass. Specifically:
- `test/active_session_cubit_test.dart` (updated for new `start(subjectId:)` signature)
- `test/semesters_cubit_test.dart` (new)
- `test/subjects_cubit_test.dart` (new)
- Pre-existing auth + token tests pass unchanged.

- [ ] **Step 3: Commit any drift**

If analyze surfaced issues you fixed inline:

```bash
git add mobile/
git commit -m "chore(mobile): post-phase analyze fixes"
```

### Task 45: End-to-end smoke on a simulator

- [ ] **Step 1: Start backend + DB**

From repo root: `docker compose up -d` (if not running).
From `backend/`: `npm run dev` (in a background terminal). Verify `http://localhost:3000/health` returns 200.

- [ ] **Step 2: Run mobile**

From `mobile/`: `flutter run --dart-define-from-file=.env` (or whatever your usual run command is — see CLAUDE.md).
Choose your simulator / device.

- [ ] **Step 3: Walk the fresh-user flow manually**

1. Register a new account (no semesters, no subjects).
2. Land on dashboard. **Verify:** no pill in the app bar title slot, no "+ add semester" prompt, normal dashboard layout with greeting + session tile + stat tiles + an empty `"your subjects"` section with only the `"+ something else"` row.
3. Tap `"+ something else"`. **Verify:** session tile's chip slot becomes an inline text field with `"what are you doing?"` placeholder. Keyboard appears.
4. Type `"reading the brothers karamazov"`. **Verify:** start button enables.
5. Tap start. **Verify:** running state — chip slot shows the typed text in plain Cocoa Ink (no color dot, no chip background), timer ticks.
6. Tap "end session". **Verify:** toast `"nice — 0 min logged"` (or similar), returns to idle, ad-hoc cleared.
7. Navigate to subjects tab via bottom nav. **Verify:** empty state with `"you haven't added any subjects yet"`, Fraunces-italic `"subjects"` title, no pill.
8. Tap `"add your first subject"`. **Verify:** sheet appears with subject fields + the inline semester section (because no semesters yet) with the framing line `"to organize subjects, group them into a term"`.
9. Fill in subject name + term name + dates (defaults already set), submit. **Verify:** sheet dismisses, toast `"<subject name> added"`, subject appears in list.
10. Navigate back to dashboard. **Verify:** pill now appears in app bar title slot showing the new term name (lowercase). Cream chip, ~32px tall.
11. Tap the pill. **Verify:** routes to `/semesters` manager. Bottom nav hides. `"active"` header with one card (the term you just created); no `"past terms"` section.
12. Tap the overflow `…` on the active card → `"delete"`. **Verify:** sheet says `"you can't delete your active term. switch to another term first, then try again."` Cancel.
13. Add a second term via `"add a term"`. Set `"make active"` toggle off. Submit. **Verify:** new card appears under `"past terms"`. Toast `"<name> added"` (not the active variant).
14. Tap the past-term card. **Verify:** card moves to top under `"active"`; previous active demotes to `"past terms"`. Toast `"<name> is now active"`.
15. Go back to dashboard. **Verify:** pill name updated to the newly-activated term. Subject list is empty (subjects belonged to the previous active semester) — this is correct behavior; SubjectsCubit.loadForSemester was called with the new id.
16. Add a subject under the new term, start a session against it, stop. Then go to subjects → swipe-delete the subject. **Verify:** toast `"sessions preserved as ad-hoc activities"`. Go to dashboard, start a new session — `_SubjectTotalsList` doesn't show during idle; tap a subject to start one and verify the `"other"` row appears after running for a moment + completing.

If any step fails, file the issue against this plan and patch the relevant task before continuing.

- [ ] **Step 4: Commit any polish fixes uncovered during smoke**

```bash
git add backend/ mobile/
git commit -m "chore: post-smoke polish"
```

### Task 46: Update CLAUDE.md / DESIGN.md / ADRs to reflect the pivot (optional but recommended)

This isn't strictly part of the implementation, but the model pivot is meaningful enough that future Claude sessions will need to know about it.

- [ ] **Step 1: Add an ADR**

Create `docs/adr/0015-semester-optional-via-adhoc.md` summarizing:
- The pivot from "semester required" to "semester optional via ad-hoc."
- Why we chose the flexibility-tweak path over a positioning shift.
- The schema change (nullable `subject_id` + `activity_name` + CHECK constraint).
- The orphan-to-ad-hoc cascade rule.
- The pill-only-when-1+-semester rule.
- Link to this plan doc.

- [ ] **Step 2: Update `CLAUDE.md`**

In the "Architecture" section, add a brief note about the ad-hoc escape valve under "Sessions can be subject-attached or ad-hoc."

In the "Design System" section, mention the `ActiveSemesterPill` widget and the `"+ something else"` chip alongside `PulpTile` and `DefaultButton`.

- [ ] **Step 3: Update `DESIGN.md`**

Add a short subsection under "Mobile implementation pattern" describing the pill and the ad-hoc chip as canonical primitives.

- [ ] **Step 4: Commit**

```bash
git add docs/adr/0015-semester-optional-via-adhoc.md CLAUDE.md DESIGN.md
git commit -m "docs: ADR-0015 — semester optional via ad-hoc activity escape valve"
```

---

## Self-review (run before declaring the plan complete)

**Spec coverage check** — every locked decision from the grilling sessions maps to a task:

| Locked decision | Task(s) |
|----|---|
| Flexibility tweak, not positioning shift | Plan scope (no rename tasks present) |
| Schema: subject_id nullable + activity_name + CHECK | Task 1 |
| Subjects require semester (no schema change) | Verified by absence of task touching subjects.semester_id |
| Ad-hoc chip in subject picker | Task 31 |
| Inline input replaces chip slot in SessionTile | Task 32 |
| Ad-hoc running-state: no marker, plain text | Task 32 (_TileHeader adHocLabel branch) |
| Pill in app bar, conditional on 1+ semesters | Task 30 + Task 40 (titleWidget pattern) |
| Pill visuals: cream chip, 32px, Radii.full, no icon | Task 30 |
| First-subject inline two-section sheet | Task 36 |
| Q7 defaults (framing line, no toggle, cancel discards, dates today + 120) | Task 36 |
| "other" aggregate row | Task 40 + Task 42 |
| Orphan-on-delete (subject + semester cascade) | Tasks 9, 10, 5 (orphanBySubjectId) |
| Subjects screen pill in title | Task 41 |
| Post-action toasts (create / activate / delete) | Tasks 37, 41, 40 |
| Stats endpoint | Tasks 11, 12 |
| Cubit coordination via shell BlocListener | Task 39 |
| SubjectsNoSemesters removed | Task 27 |
| ActiveSessionCubit.startAdHoc | Task 29 |
| Top-level /semesters route | Task 38 |
| Cascade preview blocks active deletion | Task 10 + Task 35 (UI mirror) |

**Placeholder scan** — searched for: "TBD", "TODO", "implement later", "fill in details", "Similar to Task". Two intentional notes remain:

- Task 30 — `kFontGeist` symbol verification note. Engineer must look up the actual constant.
- Task 42 — small layer-bend explanation around `ISessionRepository` injection into the stats cubit; acceptable trade-off for v1 explicitly justified.

**Type consistency check** —
- `SubjectsLoaded.semesterId` (Task 27) — matches `loadForSemester(String?)` signature throughout.
- `SemesterFormResult.create / update` (Task 34) — caller pattern in Task 37 dispatches correctly to `create / update / activate`.
- `SubjectFormResult.inlineSemester` (Task 36) sentinel value `__inline__` — Task 41 caller checks `result.inlineSemester != null` first, so the sentinel never reaches the create call.
- `StartSessionPayload.forSubject` / `adHoc` (Task 20) — `_startWithPayload` in Task 29 uses both correctly.
- `orphanBySubjectId` (Task 4) — called by `DeleteSubject` (Task 9) and `DeleteSemester` (Task 10) with matching args.
- `DashboardStatsLoaded.adHocSeconds` (Task 42) — referenced by `_SubjectTotalsList` in Task 40; both tasks must land together or the workaround in Task 40 Step 1 applies.

**Spec / task gaps fixed during review** —

- The pill visibility on the dashboard requires `MainAppBar` to accept a `titleWidget`. Task 40 Step 2 adds this — confirmed in plan.
- `_SubjectTotalsList` previously rendered nothing when subjects were empty; now it must render *something* if ad-hoc time exists. Task 40's `if (stats.isEmpty && adHocSeconds == 0) return const SizedBox.shrink();` correctly handles this.

---

## Plan complete — execution handoff

**"Plan complete and saved to `docs/superpowers/plans/2026-05-24-warm-studygram-semester-adhoc.md`. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Fresh subagent per task + two-stage review

**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review


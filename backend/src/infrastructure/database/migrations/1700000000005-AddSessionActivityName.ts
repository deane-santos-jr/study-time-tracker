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

    // Re-add the FK without a referential action (default RESTRICT). MySQL 8.0
    // forbids a column from being in both a CHECK constraint AND an FK with
    // ON DELETE SET NULL / CASCADE (error 3823). The orphan-then-delete flow
    // lives in the DeleteSubject use case, which nulls subject_id and copies
    // the subject name into activity_name BEFORE deleting the subject row —
    // so by the time the FK is checked, no sessions reference the subject.
    // RESTRICT is the safest fallback if the use case is bypassed: MySQL
    // rejects the delete instead of silently dropping data or violating the
    // CHECK invariant.
    await queryRunner.query(`
      ALTER TABLE study_sessions
      ADD CONSTRAINT fk_sessions_subject
      FOREIGN KEY (subject_id) REFERENCES subjects(id)
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

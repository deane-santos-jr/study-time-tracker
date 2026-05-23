import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddSubjectSemesterId1700000000004 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Backfill any existing rows to the user's first semester before enforcing
    // NOT NULL. New installs have no rows so this is a no-op.
    await queryRunner.query(`
      ALTER TABLE subjects
      ADD COLUMN semester_id VARCHAR(36) NULL AFTER user_id
    `);
    await queryRunner.query(`
      UPDATE subjects s
      JOIN (
        SELECT user_id, MIN(id) AS semester_id
        FROM semesters
        GROUP BY user_id
      ) sem ON sem.user_id = s.user_id
      SET s.semester_id = sem.semester_id
      WHERE s.semester_id IS NULL
    `);
    await queryRunner.query(`
      DELETE FROM subjects WHERE semester_id IS NULL
    `);
    await queryRunner.query(`
      ALTER TABLE subjects
      MODIFY COLUMN semester_id VARCHAR(36) NOT NULL
    `);
    await queryRunner.query(`
      ALTER TABLE subjects
      ADD CONSTRAINT fk_subjects_semester
      FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE
    `);
    await queryRunner.query(`
      CREATE INDEX idx_subjects_semester ON subjects (semester_id)
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX idx_subjects_semester ON subjects`);
    await queryRunner.query(`ALTER TABLE subjects DROP FOREIGN KEY fk_subjects_semester`);
    await queryRunner.query(`ALTER TABLE subjects DROP COLUMN semester_id`);
  }
}

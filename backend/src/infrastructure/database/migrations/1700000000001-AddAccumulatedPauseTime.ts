import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddAccumulatedPauseTime1700000000001 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'study_sessions',
      new TableColumn({
        name: 'accumulated_pause_time',
        type: 'int',
        isNullable: true,
        default: 0,
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('study_sessions', 'accumulated_pause_time');
  }
}

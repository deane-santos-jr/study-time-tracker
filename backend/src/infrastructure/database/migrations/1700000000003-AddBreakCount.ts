import { MigrationInterface, QueryRunner, TableColumn } from 'typeorm';

export class AddBreakCount1700000000003 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn(
      'study_sessions',
      new TableColumn({
        name: 'break_count',
        type: 'int',
        isNullable: false,
        default: 0,
      })
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('study_sessions', 'break_count');
  }
}

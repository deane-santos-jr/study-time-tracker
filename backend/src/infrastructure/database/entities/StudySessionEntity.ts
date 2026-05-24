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

  // FK has no referential action in the DB (default RESTRICT) — see the
  // migration AddSessionActivityName1700000000005 for rationale (MySQL forbids
  // both a CHECK constraint and ON DELETE SET NULL on the same column).
  @ManyToOne(() => SubjectEntity, (subject) => subject.sessions, {
    onDelete: 'RESTRICT',
    nullable: true,
  })
  @JoinColumn({ name: 'subject_id' })
  subject!: SubjectEntity | null;

  @OneToMany(() => BreakEntity, (breakEntity) => breakEntity.session)
  breaks?: BreakEntity[];
}

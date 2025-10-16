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

  @Column({ name: 'subject_id' })
  subjectId!: string;

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

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => UserEntity, (user) => user.sessions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @ManyToOne(() => SubjectEntity, (subject) => subject.sessions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'subject_id' })
  subject!: SubjectEntity;

  @OneToMany(() => BreakEntity, (breakEntity) => breakEntity.session)
  breaks?: BreakEntity[];
}

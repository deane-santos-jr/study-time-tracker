import { Entity, PrimaryColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { StudySessionEntity } from './StudySessionEntity';

@Entity('breaks')
export class BreakEntity {
  @PrimaryColumn('varchar', { length: 36 })
  id!: string;

  @Column({ name: 'session_id' })
  sessionId!: string;

  @Column({ name: 'start_time', type: 'datetime' })
  startTime!: Date;

  @Column({ name: 'end_time', type: 'datetime', nullable: true })
  endTime?: Date;

  @Column({ type: 'int', nullable: true })
  duration?: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @ManyToOne(() => StudySessionEntity, (session) => session.breaks, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session!: StudySessionEntity;
}

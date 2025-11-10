import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { UserEntity } from './UserEntity';
import { StudySessionEntity } from './StudySessionEntity';

@Entity('notes')
export class NoteEntity {
  @PrimaryColumn('varchar', { length: 36 })
  id!: string;

  @Column({ name: 'session_id' })
  sessionId!: string;

  @Column({ name: 'user_id' })
  userId!: string;

  @Column({ type: 'text' })
  content!: string;

  @Column({ type: 'text', nullable: true })
  topics?: string;

  @Column({ name: 'difficulty_level', type: 'int', nullable: true })
  difficultyLevel?: number;

  @Column({ name: 'focus_level', type: 'int', nullable: true })
  focusLevel?: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => UserEntity, (user) => user.sessions, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @ManyToOne(() => StudySessionEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'session_id' })
  session!: StudySessionEntity;
}

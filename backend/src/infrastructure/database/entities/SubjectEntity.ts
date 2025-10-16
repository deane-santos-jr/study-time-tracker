import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { UserEntity } from './UserEntity';
import { SemesterEntity } from './SemesterEntity';
import { StudySessionEntity } from './StudySessionEntity';

@Entity('subjects')
export class SubjectEntity {
  @PrimaryColumn('varchar', { length: 36 })
  id!: string;

  @Column({ name: 'user_id' })
  userId!: string;

  @Column({ name: 'semester_id' })
  semesterId!: string;

  @Column()
  name!: string;

  @Column({ length: 7 })
  color!: string;

  @Column({ nullable: true, length: 50 })
  icon?: string;

  @Column({ name: 'is_active', default: true })
  isActive!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @ManyToOne(() => UserEntity, (user) => user.subjects, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: UserEntity;

  @ManyToOne(() => SemesterEntity, (semester) => semester.subjects, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'semester_id' })
  semester!: SemesterEntity;

  @OneToMany(() => StudySessionEntity, (session) => session.subject)
  sessions?: StudySessionEntity[];
}

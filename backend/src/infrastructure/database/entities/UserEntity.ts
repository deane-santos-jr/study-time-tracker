import { Entity, PrimaryColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from 'typeorm';
import { SubjectEntity } from './SubjectEntity';
import { SemesterEntity } from './SemesterEntity';
import { StudySessionEntity } from './StudySessionEntity';

@Entity('users')
export class UserEntity {
  @PrimaryColumn('varchar', { length: 36 })
  id!: string;

  @Column({ unique: true })
  email!: string;

  @Column()
  password!: string;

  @Column({ name: 'first_name' })
  firstName!: string;

  @Column({ name: 'last_name' })
  lastName!: string;

  @Column({ name: 'is_active', default: true })
  isActive!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;

  @OneToMany(() => SubjectEntity, (subject) => subject.user)
  subjects?: SubjectEntity[];

  @OneToMany(() => SemesterEntity, (semester) => semester.user)
  semesters?: SemesterEntity[];

  @OneToMany(() => StudySessionEntity, (session) => session.user)
  sessions?: StudySessionEntity[];
}

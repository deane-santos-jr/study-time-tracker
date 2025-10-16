import { StudySession } from '../entities/StudySession';

export interface IStudySessionRepository {
  create(session: StudySession): Promise<StudySession>;
  findById(id: string): Promise<StudySession | null>;
  findByUserId(userId: string): Promise<StudySession[]>;
  findActiveByUserId(userId: string): Promise<StudySession | null>;
  findBySubjectId(subjectId: string): Promise<StudySession[]>;
  findBySemesterId(semesterId: string): Promise<StudySession[]>;
  update(session: StudySession): Promise<StudySession>;
  delete(id: string): Promise<void>;
}

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

  /**
   * Convert every session belonging to the given subject into an ad-hoc
   * session. Used by DeleteSubject (and transitively by DeleteSemester) to
   * preserve history when a subject is removed. Sets subject_id=NULL,
   * semester_id=NULL, activity_name=<provided>, and returns the number of
   * rows affected.
   */
  orphanBySubjectId(subjectId: string, activityName: string): Promise<number>;
}

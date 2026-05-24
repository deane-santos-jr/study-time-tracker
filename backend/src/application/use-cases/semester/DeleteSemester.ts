import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import {
  NotFoundError,
  ForbiddenError,
  ValidationError,
} from '../../../shared/errors/AppError';

export interface DeleteSemesterResult {
  orphanedSubjectCount: number;
  orphanedSessionCount: number;
}

export class DeleteSemester {
  constructor(
    private semesterRepository: ISemesterRepository,
    private subjectRepository: ISubjectRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, semesterId: string): Promise<DeleteSemesterResult> {
    const semester = await this.semesterRepository.findById(semesterId);

    if (!semester) {
      throw new NotFoundError('Semester not found');
    }

    if (!semester.belongsToUser(userId)) {
      throw new ForbiddenError('You do not have permission to delete this semester');
    }

    if (semester.isActive) {
      throw new ValidationError(
        'Cannot delete the active semester. Switch active first.'
      );
    }

    const allSubjects = await this.subjectRepository.findByUserId(userId);
    const subjectsInSemester = allSubjects.filter(
      (s) => s.semesterId === semesterId
    );

    let totalOrphanedSessions = 0;
    for (const subject of subjectsInSemester) {
      const orphanedCount = await this.sessionRepository.orphanBySubjectId(
        subject.id,
        subject.name
      );
      totalOrphanedSessions += orphanedCount;
      await this.subjectRepository.delete(subject.id);
    }

    await this.semesterRepository.delete(semesterId);

    return {
      orphanedSubjectCount: subjectsInSemester.length,
      orphanedSessionCount: totalOrphanedSessions,
    };
  }
}

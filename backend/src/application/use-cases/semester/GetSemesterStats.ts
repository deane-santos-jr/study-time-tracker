import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export interface SemesterStats {
  subjectCount: number;
  sessionCount: number;
  totalSeconds: number;
}

export class GetSemesterStats {
  constructor(
    private semesterRepository: ISemesterRepository,
    private subjectRepository: ISubjectRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, semesterId: string): Promise<SemesterStats> {
    const semester = await this.semesterRepository.findById(semesterId);
    if (!semester) {
      throw new NotFoundError('Semester not found');
    }
    if (!semester.belongsToUser(userId)) {
      throw new ForbiddenError(
        'You do not have permission to view this semester'
      );
    }

    const allSubjects = await this.subjectRepository.findByUserId(userId);
    const subjectsInSemester = allSubjects.filter(
      (s) => s.semesterId === semesterId
    );

    let sessionCount = 0;
    let totalSeconds = 0;
    for (const subject of subjectsInSemester) {
      const sessions = await this.sessionRepository.findBySubjectId(subject.id);
      for (const session of sessions) {
        if (session.status === 'COMPLETED') {
          sessionCount += 1;
          totalSeconds += session.effectiveStudyTime ?? 0;
        }
      }
    }

    return { subjectCount: subjectsInSemester.length, sessionCount, totalSeconds };
  }
}

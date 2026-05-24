import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export interface DeleteSubjectResult {
  orphanedSessionCount: number;
}

export class DeleteSubject {
  constructor(
    private subjectRepository: ISubjectRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, subjectId: string): Promise<DeleteSubjectResult> {
    const subject = await this.subjectRepository.findById(subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }

    if (subject.userId !== userId) {
      throw new ForbiddenError('You do not have permission to delete this subject');
    }

    // Orphan sessions first — copy the subject's name into activity_name so
    // the history is preserved as ad-hoc records.
    const orphanedSessionCount = await this.sessionRepository.orphanBySubjectId(
      subjectId,
      subject.name
    );

    await this.subjectRepository.delete(subjectId);

    return { orphanedSessionCount };
  }
}

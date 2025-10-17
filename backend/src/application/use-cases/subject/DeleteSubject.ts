import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export class DeleteSubject {
  constructor(private subjectRepository: ISubjectRepository) {}

  async execute(userId: string, subjectId: string): Promise<void> {
    const subject = await this.subjectRepository.findById(subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }

    if (subject.userId !== userId) {
      throw new ForbiddenError('You do not have permission to delete this subject');
    }

    await this.subjectRepository.delete(subjectId);
  }
}

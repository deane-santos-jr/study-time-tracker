import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export class DeleteSubject {
  constructor(private subjectRepository: ISubjectRepository) {}

  async execute(userId: string, subjectId: string): Promise<void> {
    // Find subject
    const subject = await this.subjectRepository.findById(subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }

    // Check ownership
    if (subject.userId !== userId) {
      throw new ForbiddenError('You do not have permission to delete this subject');
    }

    // Soft delete
    await this.subjectRepository.delete(subjectId);
  }
}

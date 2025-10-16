import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export class DeleteSemester {
  constructor(private semesterRepository: ISemesterRepository) {}

  async execute(userId: string, semesterId: string): Promise<void> {
    const semester = await this.semesterRepository.findById(semesterId);

    if (!semester) {
      throw new NotFoundError('Semester not found');
    }

    if (!semester.belongsToUser(userId)) {
      throw new ForbiddenError('You do not have permission to delete this semester');
    }

    await this.semesterRepository.delete(semesterId);
  }
}

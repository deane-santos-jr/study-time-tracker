import { Semester } from '../../../domain/entities/Semester';
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';

export class GetActiveSemester {
  constructor(private semesterRepository: ISemesterRepository) {}

  async execute(userId: string): Promise<Semester | null> {
    return await this.semesterRepository.findActiveByUserId(userId);
  }
}

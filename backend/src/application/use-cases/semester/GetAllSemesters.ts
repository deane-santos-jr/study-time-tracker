import { Semester } from '../../../domain/entities/Semester';
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';

export class GetAllSemesters {
  constructor(private semesterRepository: ISemesterRepository) {}

  async execute(userId: string): Promise<Semester[]> {
    return await this.semesterRepository.findByUserId(userId);
  }
}

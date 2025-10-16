import { Subject } from '../../../domain/entities/Subject';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';

export class GetAllSubjects {
  constructor(private subjectRepository: ISubjectRepository) {}

  async execute(userId: string): Promise<Subject[]> {
    return await this.subjectRepository.findByUserId(userId);
  }
}

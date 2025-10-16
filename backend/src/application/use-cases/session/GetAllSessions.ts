import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';

export class GetAllSessions {
  constructor(private sessionRepository: IStudySessionRepository) {}

  async execute(userId: string): Promise<StudySession[]> {
    return await this.sessionRepository.findByUserId(userId);
  }
}

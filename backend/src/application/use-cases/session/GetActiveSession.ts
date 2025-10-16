import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';

export class GetActiveSession {
  constructor(private sessionRepository: IStudySessionRepository) {}

  async execute(userId: string): Promise<StudySession | null> {
    return await this.sessionRepository.findActiveSession(userId);
  }
}

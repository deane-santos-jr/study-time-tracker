import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export class DeleteSession {
  constructor(private sessionRepository: IStudySessionRepository) {}

  async execute(userId: string, sessionId: string): Promise<void> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    await this.sessionRepository.delete(sessionId);
  }
}

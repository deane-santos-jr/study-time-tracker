import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { Break } from '../../../domain/entities/Break';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';
import { v4 as uuidv4 } from 'uuid';

export class PauseSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private breakRepository: IBreakRepository
  ) {}

  async execute(userId: string, sessionId: string): Promise<StudySession> {
    // Find session
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    // Check ownership
    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    // Pause the session (this creates a break)
    session.pause();

    // Create break record
    const breakRecord = Break.create(uuidv4(), session.id);
    await this.breakRepository.create(breakRecord);

    // Update session
    return await this.sessionRepository.update(session);
  }
}

import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export class ResumeSession {
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

    // Find active break and end it
    const breaks = await this.breakRepository.findBySessionId(session.id);
    const activeBreak = breaks.find((b) => b.endTime === null);

    if (activeBreak) {
      activeBreak.end();
      await this.breakRepository.update(activeBreak);
    }

    // Resume the session
    session.resume();

    // Update session
    return await this.sessionRepository.update(session);
  }
}

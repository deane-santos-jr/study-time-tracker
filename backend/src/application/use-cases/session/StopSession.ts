import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export class StopSession {
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

    // Get all breaks for this session
    const breaks = await this.breakRepository.findBySessionId(session.id);

    // End any active break
    const activeBreak = breaks.find((b) => b.endTime === null);
    if (activeBreak) {
      activeBreak.end();
      await this.breakRepository.update(activeBreak);
    }

    // Calculate total break time
    const totalBreakTime = breaks.reduce((sum, b) => sum + (b.duration || 0), 0);

    // Stop the session
    session.stop(totalBreakTime);

    // Update session
    return await this.sessionRepository.update(session);
  }
}

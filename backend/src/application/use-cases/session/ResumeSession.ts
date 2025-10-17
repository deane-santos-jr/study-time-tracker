import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export class ResumeSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private breakRepository: IBreakRepository
  ) {}

  async execute(userId: string, sessionId: string): Promise<StudySession & { accumulatedBreakTime?: number; hasActiveBreak?: boolean; accumulatedPauseTime?: number }> {
    // Find session
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    // Check ownership
    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    // Find active break and end it (if any)
    const breaks = await this.breakRepository.findBySessionId(session.id);
    const activeBreak = breaks.find((b) => b.endTime === null);

    let hasActiveBreak = false;
    if (activeBreak) {
      activeBreak.end();
      await this.breakRepository.update(activeBreak);
      hasActiveBreak = true;
    }

    // If paused without a break, accumulate the pause time
    if (session.pausedAt && !hasActiveBreak) {
      const pauseDuration = Math.floor((new Date().getTime() - session.pausedAt.getTime()) / 1000);
      session.accumulatedPauseTime += pauseDuration;
    }

    // Resume the session
    session.resume();

    // Update session
    const updatedSession = await this.sessionRepository.update(session);

    // Calculate accumulated break time (all breaks are now completed)
    const updatedBreaks = await this.breakRepository.findBySessionId(session.id);
    const accumulatedBreakTime = updatedBreaks.reduce((sum, b) => {
      return sum + (b.duration || 0);
    }, 0);

    // After resuming, there should be no active breaks
    return { ...updatedSession, accumulatedBreakTime, hasActiveBreak: false, accumulatedPauseTime: updatedSession.accumulatedPauseTime };
  }
}

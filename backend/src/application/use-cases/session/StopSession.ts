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
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    const breaks = await this.breakRepository.findBySessionId(session.id);

    const activeBreak = breaks.find((b) => b.endTime === null);
    if (activeBreak) {
      activeBreak.end();
      await this.breakRepository.update(activeBreak);
    }

    const totalBreakTime = breaks.reduce((sum, b) => sum + (b.duration || 0), 0);

    let totalPauseTime = session.accumulatedPauseTime;
    if (session.status === 'PAUSED' && session.pausedAt && !activeBreak) {
      const currentPauseDuration = Math.floor((new Date().getTime() - session.pausedAt.getTime()) / 1000);
      totalPauseTime += currentPauseDuration;
      session.accumulatedPauseTime = totalPauseTime;
    }

    session.stop(totalBreakTime, totalPauseTime);

    return await this.sessionRepository.update(session);
  }
}

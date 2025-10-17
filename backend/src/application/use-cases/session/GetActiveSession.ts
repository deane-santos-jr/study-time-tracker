import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';

export class GetActiveSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private breakRepository: IBreakRepository
  ) {}

  async execute(userId: string): Promise<(StudySession & { accumulatedBreakTime?: number; hasActiveBreak?: boolean; accumulatedPauseTime?: number }) | null> {
    const session = await this.sessionRepository.findActiveByUserId(userId);

    if (!session) {
      return null;
    }

    const breaks = await this.breakRepository.findBySessionId(session.id);
    let hasActiveBreak = false;

    const accumulatedBreakTime = breaks.reduce((sum, b) => {
      if (!b.endTime && session.status === 'PAUSED') {
        hasActiveBreak = true;
        const now = new Date();
        const duration = Math.floor((now.getTime() - b.startTime.getTime()) / 1000);
        return sum + duration;
      }
      return sum + (b.duration || 0);
    }, 0);

    let accumulatedPauseTime = session.accumulatedPauseTime;

    if (session.status === 'PAUSED' && !hasActiveBreak && session.pausedAt) {
      const now = new Date();
      const currentPauseDuration = Math.floor((now.getTime() - session.pausedAt.getTime()) / 1000);
      accumulatedPauseTime += currentPauseDuration;
    }

    return { ...session, accumulatedBreakTime, hasActiveBreak, accumulatedPauseTime };
  }
}

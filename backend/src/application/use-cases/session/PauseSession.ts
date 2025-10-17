import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { Break } from '../../../domain/entities/Break';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';
import { v4 as uuidv4 } from 'uuid';

export interface PauseSessionDTO {
  isBreak?: boolean;
}

export class PauseSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private breakRepository: IBreakRepository
  ) {}

  async execute(userId: string, sessionId: string, dto?: PauseSessionDTO): Promise<StudySession & { accumulatedBreakTime?: number; hasActiveBreak?: boolean; accumulatedPauseTime?: number }> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    session.pause();

    const isBreak = dto?.isBreak !== false;
    if (isBreak) {
      const breakRecord = Break.create(uuidv4(), session.id);
      await this.breakRepository.create(breakRecord);
      session.breakCount += 1;
    }

    const updatedSession = await this.sessionRepository.update(session);

    const breaks = await this.breakRepository.findBySessionId(session.id);
    let hasActiveBreak = false;

    const accumulatedBreakTime = breaks.reduce((sum, b) => {
      if (!b.endTime) {
        hasActiveBreak = true;
        return sum + 0;
      }
      return sum + (b.duration || 0);
    }, 0);

    return { ...updatedSession, accumulatedBreakTime, hasActiveBreak, accumulatedPauseTime: updatedSession.accumulatedPauseTime };
  }
}

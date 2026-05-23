import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { ValidationError, NotFoundError } from '../../../shared/errors/AppError';

export interface UpdateSessionDTO {
  subjectId?: string;
  startTime?: string;
  endTime?: string;
}

export class UpdateSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private subjectRepository: ISubjectRepository,
    private breakRepository: IBreakRepository
  ) {}

  async execute(userId: string, sessionId: string, dto: UpdateSessionDTO): Promise<StudySession> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }

    if (!session.belongsToUser(userId)) {
      throw new ValidationError('You do not have permission to update this session');
    }

    // Validate subject if being updated
    if (dto.subjectId) {
      const subject = await this.subjectRepository.findById(dto.subjectId);
      if (!subject) {
        throw new NotFoundError('Subject not found');
      }
      if (subject.userId !== userId) {
        throw new ValidationError('Subject does not belong to you');
      }
    }

    // Parse and validate times
    const newStartTime = dto.startTime ? new Date(dto.startTime) : session.startTime;
    const newEndTime = dto.endTime ? new Date(dto.endTime) : session.endTime;

    // Validate time logic
    if (isNaN(newStartTime.getTime())) {
      throw new ValidationError('Invalid start time format');
    }

    if (newEndTime && isNaN(newEndTime.getTime())) {
      throw new ValidationError('Invalid end time format');
    }

    if (newEndTime && newStartTime >= newEndTime) {
      throw new ValidationError('Start time must be before end time');
    }

    // Update the session fields
    const updatedSession = new StudySession(
      session.id,
      session.userId,
      dto.subjectId || session.subjectId,
      newStartTime,
      newEndTime,
      session.pausedAt,
      session.status,
      session.totalDuration,
      session.effectiveStudyTime,
      session.breakCount,
      session.accumulatedPauseTime,
      session.createdAt,
      new Date()
    );

    // Recalculate durations if times changed and session is completed
    if ((dto.startTime || dto.endTime) && updatedSession.endTime && updatedSession.status === 'COMPLETED') {
      const breaks = await this.breakRepository.findBySessionId(sessionId);

      const totalBreakTime = breaks.reduce((sum, breakRecord) => {
        return sum + (breakRecord.duration || 0);
      }, 0);

      updatedSession.totalDuration = Math.floor(
        (updatedSession.endTime.getTime() - updatedSession.startTime.getTime()) / 1000
      );

      // Reset accumulatedPauseTime when times are manually edited — the old
      // pause-tracking data is no longer meaningful for the new time range.
      updatedSession.accumulatedPauseTime = 0;

      const calculatedEffectiveTime = updatedSession.totalDuration - totalBreakTime;
      updatedSession.effectiveStudyTime = Math.max(0, calculatedEffectiveTime);
    }

    return await this.sessionRepository.update(updatedSession);
  }
}

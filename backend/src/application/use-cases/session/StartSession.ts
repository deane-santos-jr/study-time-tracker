import { v4 as uuidv4 } from 'uuid';
import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { ValidationError, NotFoundError, ConflictError } from '../../../shared/errors/AppError';

export interface StartSessionDTO {
  subjectId: string;
}

export class StartSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private subjectRepository: ISubjectRepository
  ) {}

  async execute(userId: string, dto: StartSessionDTO): Promise<StudySession & { accumulatedBreakTime?: number; hasActiveBreak?: boolean; accumulatedPauseTime?: number }> {
    const activeSession = await this.sessionRepository.findActiveByUserId(userId);
    if (activeSession) {
      throw new ConflictError('You already have an active session. Please stop it before starting a new one.');
    }

    const subject = await this.subjectRepository.findById(dto.subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }
    if (subject.userId !== userId) {
      throw new ValidationError('Subject does not belong to you');
    }

    const session = StudySession.create(
      uuidv4(),
      userId,
      dto.subjectId
    );

    const createdSession = await this.sessionRepository.create(session);

    return { ...createdSession, accumulatedBreakTime: 0, hasActiveBreak: false, accumulatedPauseTime: 0 };
  }
}

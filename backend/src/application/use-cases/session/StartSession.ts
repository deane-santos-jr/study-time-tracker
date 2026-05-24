import { v4 as uuidv4 } from 'uuid';
import { StudySession } from '../../../domain/entities/StudySession';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { ValidationError, NotFoundError, ConflictError } from '../../../shared/errors/AppError';

export interface StartSessionDTO {
  subjectId?: string;
  activityName?: string;
}

export class StartSession {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private subjectRepository: ISubjectRepository
  ) {}

  async execute(userId: string, dto: StartSessionDTO): Promise<StudySession & { accumulatedBreakTime?: number; hasActiveBreak?: boolean; accumulatedPauseTime?: number }> {
    const hasSubject = !!dto.subjectId;
    const hasActivity = !!dto.activityName?.trim();
    if (hasSubject === hasActivity) {
      throw new ValidationError(
        'Provide exactly one of subjectId or activityName'
      );
    }

    const activeSession = await this.sessionRepository.findActiveByUserId(userId);
    if (activeSession) {
      throw new ConflictError('You already have an active session. Please stop it before starting a new one.');
    }

    let session: StudySession;
    if (hasSubject) {
      const subject = await this.subjectRepository.findById(dto.subjectId!);
      if (!subject) {
        throw new NotFoundError('Subject not found');
      }
      if (subject.userId !== userId) {
        throw new ValidationError('Subject does not belong to you');
      }
      session = StudySession.createForSubject(
        uuidv4(),
        userId,
        dto.subjectId!,
        subject.semesterId
      );
    } else {
      const trimmed = dto.activityName!.trim();
      if (trimmed.length === 0 || trimmed.length > 100) {
        throw new ValidationError(
          'activityName must be 1-100 characters'
        );
      }
      session = StudySession.createAdHoc(uuidv4(), userId, trimmed);
    }

    const createdSession = await this.sessionRepository.create(session);
    return Object.assign(createdSession, {
      accumulatedBreakTime: 0,
      hasActiveBreak: false,
      accumulatedPauseTime: 0,
    });
  }
}

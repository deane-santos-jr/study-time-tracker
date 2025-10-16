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

  async execute(userId: string, dto: StartSessionDTO): Promise<StudySession> {
    // Check if user already has an active session
    const activeSession = await this.sessionRepository.findActiveSession(userId);
    if (activeSession) {
      throw new ConflictError('You already have an active session. Please stop it before starting a new one.');
    }

    // Validate subject exists and belongs to user
    const subject = await this.subjectRepository.findById(dto.subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }
    if (subject.userId !== userId) {
      throw new ValidationError('Subject does not belong to you');
    }

    // Create new session (semester will be accessed through subject)
    const session = StudySession.create(
      uuidv4(),
      userId,
      dto.subjectId
    );

    return await this.sessionRepository.create(session);
  }
}

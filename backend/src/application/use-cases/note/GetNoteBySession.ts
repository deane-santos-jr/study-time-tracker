import { Note } from '../../../domain/entities/Note';
import { INoteRepository } from '../../../domain/repositories/INoteRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export class GetNoteBySession {
  constructor(
    private noteRepository: INoteRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, sessionId: string): Promise<Note | null> {
    // Validate session exists and belongs to user
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }
    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    // Get note for session
    return await this.noteRepository.findBySessionId(sessionId);
  }
}

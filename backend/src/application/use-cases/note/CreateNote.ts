import { v4 as uuidv4 } from 'uuid';
import { Note } from '../../../domain/entities/Note';
import { INoteRepository } from '../../../domain/repositories/INoteRepository';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export interface CreateNoteDTO {
  sessionId: string;
  content: string;
  topics?: string;
  difficultyLevel?: number;
  focusLevel?: number;
}

export class CreateNote {
  constructor(
    private noteRepository: INoteRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async execute(userId: string, dto: CreateNoteDTO): Promise<Note> {
    // Validate session exists and belongs to user
    const session = await this.sessionRepository.findById(dto.sessionId);
    if (!session) {
      throw new NotFoundError('Session not found');
    }
    if (session.userId !== userId) {
      throw new ValidationError('Session does not belong to you');
    }

    // Check if note already exists for this session
    const existingNote = await this.noteRepository.findBySessionId(dto.sessionId);
    if (existingNote) {
      throw new ValidationError('Note already exists for this session. Use update instead.');
    }

    // Validate difficulty and focus levels
    if (dto.difficultyLevel !== undefined && (dto.difficultyLevel < 1 || dto.difficultyLevel > 5)) {
      throw new ValidationError('Difficulty level must be between 1 and 5');
    }
    if (dto.focusLevel !== undefined && (dto.focusLevel < 1 || dto.focusLevel > 5)) {
      throw new ValidationError('Focus level must be between 1 and 5');
    }

    // Create note
    const note = Note.create(
      uuidv4(),
      dto.sessionId,
      userId,
      dto.content,
      dto.topics,
      dto.difficultyLevel,
      dto.focusLevel
    );

    return await this.noteRepository.create(note);
  }
}

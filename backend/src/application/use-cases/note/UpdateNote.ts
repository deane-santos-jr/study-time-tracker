import { Note } from '../../../domain/entities/Note';
import { INoteRepository } from '../../../domain/repositories/INoteRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export interface UpdateNoteDTO {
  content?: string;
  topics?: string;
  difficultyLevel?: number;
  focusLevel?: number;
}

export class UpdateNote {
  constructor(private noteRepository: INoteRepository) {}

  async execute(userId: string, noteId: string, dto: UpdateNoteDTO): Promise<Note> {
    // Find note
    const note = await this.noteRepository.findById(noteId);
    if (!note) {
      throw new NotFoundError('Note not found');
    }

    // Check ownership
    if (!note.belongsToUser(userId)) {
      throw new ValidationError('Note does not belong to you');
    }

    // Validate difficulty and focus levels
    if (dto.difficultyLevel !== undefined && (dto.difficultyLevel < 1 || dto.difficultyLevel > 5)) {
      throw new ValidationError('Difficulty level must be between 1 and 5');
    }
    if (dto.focusLevel !== undefined && (dto.focusLevel < 1 || dto.focusLevel > 5)) {
      throw new ValidationError('Focus level must be between 1 and 5');
    }

    // Update note
    note.update(dto.content, dto.topics, dto.difficultyLevel, dto.focusLevel);

    return await this.noteRepository.update(note);
  }
}

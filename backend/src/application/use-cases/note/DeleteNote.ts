import { INoteRepository } from '../../../domain/repositories/INoteRepository';
import { NotFoundError, ValidationError } from '../../../shared/errors/AppError';

export class DeleteNote {
  constructor(private noteRepository: INoteRepository) {}

  async execute(userId: string, noteId: string): Promise<void> {
    // Find note
    const note = await this.noteRepository.findById(noteId);
    if (!note) {
      throw new NotFoundError('Note not found');
    }

    // Check ownership
    if (!note.belongsToUser(userId)) {
      throw new ValidationError('Note does not belong to you');
    }

    // Delete note
    await this.noteRepository.delete(noteId);
  }
}

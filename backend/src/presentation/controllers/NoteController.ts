import { Request, Response, NextFunction } from 'express';
import { CreateNote } from '../../application/use-cases/note/CreateNote';
import { UpdateNote } from '../../application/use-cases/note/UpdateNote';
import { DeleteNote } from '../../application/use-cases/note/DeleteNote';
import { GetNoteBySession } from '../../application/use-cases/note/GetNoteBySession';
import { INoteRepository } from '../../domain/repositories/INoteRepository';
import { IStudySessionRepository } from '../../domain/repositories/IStudySessionRepository';

export class NoteController {
  constructor(
    private noteRepository: INoteRepository,
    private sessionRepository: IStudySessionRepository
  ) {}

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const createNote = new CreateNote(this.noteRepository, this.sessionRepository);
      const note = await createNote.execute(req.userId!, req.body);

      res.status(201).json({
        success: true,
        data: note,
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updateNote = new UpdateNote(this.noteRepository);
      const note = await updateNote.execute(req.userId!, req.params.id, req.body);

      res.status(200).json({
        success: true,
        data: note,
      });
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const deleteNote = new DeleteNote(this.noteRepository);
      await deleteNote.execute(req.userId!, req.params.id);

      res.status(200).json({
        success: true,
        message: 'Note deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }

  async getBySession(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getNoteBySession = new GetNoteBySession(this.noteRepository, this.sessionRepository);
      const note = await getNoteBySession.execute(req.userId!, req.params.sessionId);

      res.status(200).json({
        success: true,
        data: note,
      });
    } catch (error) {
      next(error);
    }
  }
}

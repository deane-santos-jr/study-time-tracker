import { Repository } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { NoteEntity } from '../entities/NoteEntity';
import { INoteRepository } from '../../../domain/repositories/INoteRepository';
import { Note } from '../../../domain/entities/Note';

export class NoteRepository implements INoteRepository {
  private repository: Repository<NoteEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(NoteEntity);
  }

  async create(note: Note): Promise<Note> {
    const noteEntity = this.repository.create({
      id: note.id,
      sessionId: note.sessionId,
      userId: note.userId,
      content: note.content,
      topics: note.topics,
      difficultyLevel: note.difficultyLevel,
      focusLevel: note.focusLevel,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
    });

    const saved = await this.repository.save(noteEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<Note | null> {
    const noteEntity = await this.repository.findOne({ where: { id } });
    return noteEntity ? this.toDomain(noteEntity) : null;
  }

  async findBySessionId(sessionId: string): Promise<Note | null> {
    const noteEntity = await this.repository.findOne({ where: { sessionId } });
    return noteEntity ? this.toDomain(noteEntity) : null;
  }

  async findByUserId(userId: string): Promise<Note[]> {
    const noteEntities = await this.repository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
    return noteEntities.map((entity) => this.toDomain(entity));
  }

  async update(note: Note): Promise<Note> {
    await this.repository.update(note.id, {
      content: note.content,
      topics: note.topics,
      difficultyLevel: note.difficultyLevel,
      focusLevel: note.focusLevel,
      updatedAt: new Date(),
    });

    const updated = await this.repository.findOne({ where: { id: note.id } });
    if (!updated) {
      throw new Error('Note not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  private toDomain(entity: NoteEntity): Note {
    return new Note(
      entity.id,
      entity.sessionId,
      entity.userId,
      entity.content,
      entity.topics,
      entity.difficultyLevel,
      entity.focusLevel,
      entity.createdAt,
      entity.updatedAt
    );
  }
}

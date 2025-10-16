import { Repository } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { StudySessionEntity } from '../entities/StudySessionEntity';
import { IStudySessionRepository } from '../../../domain/repositories/IStudySessionRepository';
import { StudySession, SessionStatus } from '../../../domain/entities/StudySession';

export class StudySessionRepository implements IStudySessionRepository {
  private repository: Repository<StudySessionEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(StudySessionEntity);
  }

  async create(session: StudySession): Promise<StudySession> {
    const sessionEntity = this.repository.create({
      id: session.id,
      userId: session.userId,
      subjectId: session.subjectId,
      startTime: session.startTime,
      endTime: session.endTime,
      pausedAt: session.pausedAt,
      status: session.status,
      totalDuration: session.totalDuration,
      effectiveStudyTime: session.effectiveStudyTime,
      breakCount: session.breakCount,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    });

    const saved = await this.repository.save(sessionEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<StudySession | null> {
    const sessionEntity = await this.repository.findOne({ where: { id } });
    return sessionEntity ? this.toDomain(sessionEntity) : null;
  }

  async findByUserId(userId: string): Promise<StudySession[]> {
    const sessionEntities = await this.repository.find({
      where: { userId },
      order: { startTime: 'DESC' },
    });
    return sessionEntities.map((entity) => this.toDomain(entity));
  }

  async findActiveSession(userId: string): Promise<StudySession | null> {
    const sessionEntity = await this.repository.findOne({
      where: [
        { userId, status: SessionStatus.ACTIVE },
        { userId, status: SessionStatus.PAUSED },
      ],
      order: { startTime: 'DESC' },
    });
    return sessionEntity ? this.toDomain(sessionEntity) : null;
  }

  async findBySubjectId(subjectId: string): Promise<StudySession[]> {
    const sessionEntities = await this.repository.find({
      where: { subjectId },
      order: { startTime: 'DESC' },
    });
    return sessionEntities.map((entity) => this.toDomain(entity));
  }

  async findBySemesterId(semesterId: string): Promise<StudySession[]> {
    const sessionEntities = await this.repository.find({
      where: { semesterId },
      order: { startTime: 'DESC' },
    });
    return sessionEntities.map((entity) => this.toDomain(entity));
  }

  async update(session: StudySession): Promise<StudySession> {
    await this.repository.update(session.id, {
      endTime: session.endTime,
      pausedAt: session.pausedAt,
      status: session.status,
      totalDuration: session.totalDuration,
      effectiveStudyTime: session.effectiveStudyTime,
      breakCount: session.breakCount,
      updatedAt: new Date(),
    });

    const updated = await this.repository.findOne({ where: { id: session.id } });
    if (!updated) {
      throw new Error('Session not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  private toDomain(entity: StudySessionEntity): StudySession {
    return new StudySession(
      entity.id,
      entity.userId,
      entity.subjectId,
      entity.startTime,
      entity.endTime,
      entity.pausedAt,
      entity.status as SessionStatus,
      entity.totalDuration,
      entity.effectiveStudyTime,
      entity.breakCount,
      entity.createdAt,
      entity.updatedAt
    );
  }
}

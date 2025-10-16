import { Repository } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { BreakEntity } from '../entities/BreakEntity';
import { IBreakRepository } from '../../../domain/repositories/IBreakRepository';
import { Break } from '../../../domain/entities/Break';

export class BreakRepository implements IBreakRepository {
  private repository: Repository<BreakEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(BreakEntity);
  }

  async create(breakRecord: Break): Promise<Break> {
    const breakEntity = this.repository.create({
      id: breakRecord.id,
      sessionId: breakRecord.sessionId,
      startTime: breakRecord.startTime,
      endTime: breakRecord.endTime,
      duration: breakRecord.duration,
      createdAt: breakRecord.createdAt,
    });

    const saved = await this.repository.save(breakEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<Break | null> {
    const breakEntity = await this.repository.findOne({ where: { id } });
    return breakEntity ? this.toDomain(breakEntity) : null;
  }

  async findBySessionId(sessionId: string): Promise<Break[]> {
    const breakEntities = await this.repository.find({
      where: { sessionId },
      order: { startTime: 'ASC' },
    });
    return breakEntities.map((entity) => this.toDomain(entity));
  }

  async update(breakRecord: Break): Promise<Break> {
    await this.repository.update(breakRecord.id, {
      endTime: breakRecord.endTime,
      duration: breakRecord.duration,
    });

    const updated = await this.repository.findOne({ where: { id: breakRecord.id } });
    if (!updated) {
      throw new Error('Break not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  private toDomain(entity: BreakEntity): Break {
    return new Break(
      entity.id,
      entity.sessionId,
      entity.startTime,
      entity.endTime,
      entity.duration,
      entity.createdAt
    );
  }
}

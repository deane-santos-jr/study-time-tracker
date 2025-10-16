import { Repository } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { SemesterEntity } from '../entities/SemesterEntity';
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { Semester } from '../../../domain/entities/Semester';

export class SemesterRepository implements ISemesterRepository {
  private repository: Repository<SemesterEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(SemesterEntity);
  }

  async create(semester: Semester): Promise<Semester> {
    const semesterEntity = this.repository.create({
      id: semester.id,
      userId: semester.userId,
      name: semester.name,
      startDate: semester.startDate,
      endDate: semester.endDate,
      isActive: semester.isActive,
      createdAt: semester.createdAt,
      updatedAt: semester.updatedAt,
    });

    const saved = await this.repository.save(semesterEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<Semester | null> {
    const semesterEntity = await this.repository.findOne({ where: { id } });
    return semesterEntity ? this.toDomain(semesterEntity) : null;
  }

  async findByUserId(userId: string): Promise<Semester[]> {
    const semesterEntities = await this.repository.find({
      where: { userId },
      order: { startDate: 'DESC' },
    });
    return semesterEntities.map((entity) => this.toDomain(entity));
  }

  async findActiveByUserId(userId: string): Promise<Semester | null> {
    const now = new Date();
    const semesterEntity = await this.repository.findOne({
      where: {
        userId,
        isActive: true,
      },
      order: { startDate: 'DESC' },
    });

    if (!semesterEntity) return null;

    // Check if current date is within semester range
    if (now >= semesterEntity.startDate && now <= semesterEntity.endDate) {
      return this.toDomain(semesterEntity);
    }

    return null;
  }

  async update(semester: Semester): Promise<Semester> {
    await this.repository.update(semester.id, {
      name: semester.name,
      startDate: semester.startDate,
      endDate: semester.endDate,
      isActive: semester.isActive,
      updatedAt: new Date(),
    });

    const updated = await this.repository.findOne({ where: { id: semester.id } });
    if (!updated) {
      throw new Error('Semester not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    // Soft delete
    await this.repository.update(id, { isActive: false, updatedAt: new Date() });
  }

  private toDomain(entity: SemesterEntity): Semester {
    return new Semester(
      entity.id,
      entity.userId,
      entity.name,
      entity.startDate,
      entity.endDate,
      entity.isActive,
      entity.createdAt,
      entity.updatedAt
    );
  }
}

import { Repository } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { SubjectEntity } from '../entities/SubjectEntity';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { Subject } from '../../../domain/entities/Subject';

export class SubjectRepository implements ISubjectRepository {
  private repository: Repository<SubjectEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(SubjectEntity);
  }

  async create(subject: Subject): Promise<Subject> {
    const subjectEntity = this.repository.create({
      id: subject.id,
      userId: subject.userId,
      semesterId: subject.semesterId,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      isActive: subject.isActive,
      createdAt: subject.createdAt,
      updatedAt: subject.updatedAt,
    });

    const saved = await this.repository.save(subjectEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<Subject | null> {
    const subjectEntity = await this.repository.findOne({ where: { id } });
    return subjectEntity ? this.toDomain(subjectEntity) : null;
  }

  async findByUserId(userId: string): Promise<Subject[]> {
    const subjectEntities = await this.repository.find({
      where: { userId, isActive: true },
      order: { createdAt: 'DESC' },
    });
    return subjectEntities.map((entity) => this.toDomain(entity));
  }

  async update(subject: Subject): Promise<Subject> {
    await this.repository.update(subject.id, {
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      isActive: subject.isActive,
      updatedAt: new Date(),
    });

    const updated = await this.repository.findOne({ where: { id: subject.id } });
    if (!updated) {
      throw new Error('Subject not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    // Soft delete by setting isActive to false
    await this.repository.update(id, { isActive: false, updatedAt: new Date() });
  }

  private toDomain(entity: SubjectEntity): Subject {
    return new Subject(
      entity.id,
      entity.userId,
      entity.semesterId,
      entity.name,
      entity.color,
      entity.icon,
      entity.isActive,
      entity.createdAt,
      entity.updatedAt
    );
  }
}

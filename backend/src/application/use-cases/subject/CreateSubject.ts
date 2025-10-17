import { v4 as uuidv4 } from 'uuid';
import { Subject } from '../../../domain/entities/Subject';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ValidationError, NotFoundError } from '../../../shared/errors/AppError';

export interface CreateSubjectDTO {
  name: string;
  color: string;
  icon?: string;
  semesterId: string;
}

export class CreateSubject {
  constructor(
    private subjectRepository: ISubjectRepository,
    private semesterRepository: ISemesterRepository
  ) {}

  async execute(userId: string, dto: CreateSubjectDTO): Promise<Subject> {
    this.validateInput(dto);

    const semester = await this.semesterRepository.findById(dto.semesterId);
    if (!semester) {
      throw new NotFoundError('Semester not found');
    }
    if (semester.userId !== userId) {
      throw new ValidationError('Semester does not belong to you');
    }

    const subject = Subject.create(
      uuidv4(),
      userId,
      dto.semesterId,
      dto.name.trim(),
      dto.color,
      dto.icon || '📚'
    );

    return await this.subjectRepository.create(subject);
  }

  private validateInput(dto: CreateSubjectDTO): void {
    if (!dto.name || dto.name.trim().length === 0) {
      throw new ValidationError('Subject name is required');
    }

    if (dto.name.trim().length > 100) {
      throw new ValidationError('Subject name must be less than 100 characters');
    }

    if (!dto.color || !this.isValidHexColor(dto.color)) {
      throw new ValidationError('Valid hex color is required (e.g., #FF5733)');
    }
  }

  private isValidHexColor(color: string): boolean {
    return /^#[0-9A-F]{6}$/i.test(color);
  }
}

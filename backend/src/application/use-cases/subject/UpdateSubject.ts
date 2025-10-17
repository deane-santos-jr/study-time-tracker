import { Subject } from '../../../domain/entities/Subject';
import { ISubjectRepository } from '../../../domain/repositories/ISubjectRepository';
import { ValidationError, NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export interface UpdateSubjectDTO {
  name?: string;
  color?: string;
  icon?: string;
}

export class UpdateSubject {
  constructor(private subjectRepository: ISubjectRepository) {}

  async execute(userId: string, subjectId: string, dto: UpdateSubjectDTO): Promise<Subject> {
    const subject = await this.subjectRepository.findById(subjectId);
    if (!subject) {
      throw new NotFoundError('Subject not found');
    }

    if (subject.userId !== userId) {
      throw new ForbiddenError('You do not have permission to update this subject');
    }

    if (dto.name !== undefined) {
      if (dto.name.trim().length === 0) {
        throw new ValidationError('Subject name cannot be empty');
      }
      if (dto.name.trim().length > 100) {
        throw new ValidationError('Subject name must be less than 100 characters');
      }
      subject.updateName(dto.name.trim());
    }

    if (dto.color !== undefined) {
      if (!this.isValidHexColor(dto.color)) {
        throw new ValidationError('Valid hex color is required (e.g., #FF5733)');
      }
      subject.updateColor(dto.color);
    }

    if (dto.icon !== undefined) {
      subject.updateIcon(dto.icon);
    }

    return await this.subjectRepository.update(subject);
  }

  private isValidHexColor(color: string): boolean {
    return /^#[0-9A-F]{6}$/i.test(color);
  }
}

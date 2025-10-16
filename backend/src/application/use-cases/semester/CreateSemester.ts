import { v4 as uuidv4 } from 'uuid';
import { Semester } from '../../../domain/entities/Semester';
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ValidationError } from '../../../shared/errors/AppError';

export interface CreateSemesterDTO {
  name: string;
  startDate: Date;
  endDate: Date;
}

export class CreateSemester {
  constructor(private semesterRepository: ISemesterRepository) {}

  async execute(userId: string, dto: CreateSemesterDTO): Promise<Semester> {
    this.validateInput(dto);

    const semester = Semester.create(
      uuidv4(),
      userId,
      dto.name.trim(),
      dto.startDate,
      dto.endDate
    );

    return await this.semesterRepository.create(semester);
  }

  private validateInput(dto: CreateSemesterDTO): void {
    if (!dto.name || dto.name.trim().length === 0) {
      throw new ValidationError('Semester name is required');
    }

    if (dto.name.trim().length > 100) {
      throw new ValidationError('Semester name must be less than 100 characters');
    }

    if (!dto.startDate || !dto.endDate) {
      throw new ValidationError('Start date and end date are required');
    }

    if (new Date(dto.startDate) >= new Date(dto.endDate)) {
      throw new ValidationError('Start date must be before end date');
    }
  }
}

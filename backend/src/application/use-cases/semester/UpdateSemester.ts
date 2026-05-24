import { Semester } from '../../../domain/entities/Semester';
import { ISemesterRepository } from '../../../domain/repositories/ISemesterRepository';
import { ValidationError, NotFoundError, ForbiddenError } from '../../../shared/errors/AppError';

export interface UpdateSemesterDTO {
  name?: string;
  startDate?: Date;
  endDate?: Date;
  isActive?: boolean;
}

export class UpdateSemester {
  constructor(private semesterRepository: ISemesterRepository) {}

  async execute(userId: string, semesterId: string, dto: UpdateSemesterDTO): Promise<Semester> {
    const semester = await this.semesterRepository.findById(semesterId);

    if (!semester) {
      throw new NotFoundError('Semester not found');
    }

    if (!semester.belongsToUser(userId)) {
      throw new ForbiddenError('You do not have permission to update this semester');
    }

    this.validateInput(dto, semester);

    if (dto.name !== undefined) {
      semester.name = dto.name.trim();
    }

    if (dto.startDate !== undefined) {
      semester.startDate = new Date(dto.startDate);
    }

    if (dto.endDate !== undefined) {
      semester.endDate = new Date(dto.endDate);
    }

    if (dto.isActive !== undefined) {
      if (dto.isActive) {
        // Enforce at-most-one-active per user: deactivate any other active
        // semester before activating this one. The mobile / web clients
        // assume a single active term (the dashboard pill, "active" badge,
        // and active-term subject filtering all key off it), so the
        // invariant lives in the use case rather than the client.
        const others = await this.semesterRepository.findByUserId(userId);
        for (const other of others) {
          if (other.id !== semester.id && other.isActive) {
            other.deactivate();
            other.updatedAt = new Date();
            await this.semesterRepository.update(other);
          }
        }
        semester.activate();
      } else {
        semester.deactivate();
      }
    }

    semester.updatedAt = new Date();

    return await this.semesterRepository.update(semester);
  }

  private validateInput(dto: UpdateSemesterDTO, semester: Semester): void {
    if (dto.name !== undefined && dto.name.trim().length === 0) {
      throw new ValidationError('Semester name cannot be empty');
    }

    if (dto.name !== undefined && dto.name.trim().length > 100) {
      throw new ValidationError('Semester name must be less than 100 characters');
    }

    const startDate = dto.startDate ? new Date(dto.startDate) : semester.startDate;
    const endDate = dto.endDate ? new Date(dto.endDate) : semester.endDate;

    if (startDate >= endDate) {
      throw new ValidationError('Start date must be before end date');
    }
  }
}

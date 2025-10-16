import { Request, Response, NextFunction } from 'express';
import { CreateSemester } from '../../application/use-cases/semester/CreateSemester';
import { GetAllSemesters } from '../../application/use-cases/semester/GetAllSemesters';
import { UpdateSemester } from '../../application/use-cases/semester/UpdateSemester';
import { DeleteSemester } from '../../application/use-cases/semester/DeleteSemester';
import { GetActiveSemester } from '../../application/use-cases/semester/GetActiveSemester';
import { SemesterRepository } from '../../infrastructure/database/repositories/SemesterRepository';

export class SemesterController {
  private semesterRepository: SemesterRepository;

  constructor() {
    this.semesterRepository = new SemesterRepository();
  }

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const createSemester = new CreateSemester(this.semesterRepository);
      const userId = req.userId!;

      const semester = await createSemester.execute(userId, req.body);

      res.status(201).json({
        success: true,
        message: 'Semester created successfully',
        data: semester,
      });
    } catch (error) {
      next(error);
    }
  }

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getAllSemesters = new GetAllSemesters(this.semesterRepository);
      const userId = req.userId!;

      const semesters = await getAllSemesters.execute(userId);

      res.status(200).json({
        success: true,
        message: 'Semesters retrieved successfully',
        data: semesters,
      });
    } catch (error) {
      next(error);
    }
  }

  async getActive(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getActiveSemester = new GetActiveSemester(this.semesterRepository);
      const userId = req.userId!;

      const semester = await getActiveSemester.execute(userId);

      res.status(200).json({
        success: true,
        message: semester ? 'Active semester found' : 'No active semester',
        data: semester,
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updateSemester = new UpdateSemester(this.semesterRepository);
      const userId = req.userId!;
      const { id } = req.params;

      const semester = await updateSemester.execute(userId, id, req.body);

      res.status(200).json({
        success: true,
        message: 'Semester updated successfully',
        data: semester,
      });
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const deleteSemester = new DeleteSemester(this.semesterRepository);
      const userId = req.userId!;
      const { id } = req.params;

      await deleteSemester.execute(userId, id);

      res.status(200).json({
        success: true,
        message: 'Semester deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }
}

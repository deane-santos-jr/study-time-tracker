import { Request, Response, NextFunction } from 'express';
import { CreateSubject } from '../../application/use-cases/subject/CreateSubject';
import { GetAllSubjects } from '../../application/use-cases/subject/GetAllSubjects';
import { UpdateSubject } from '../../application/use-cases/subject/UpdateSubject';
import { DeleteSubject } from '../../application/use-cases/subject/DeleteSubject';
import { SubjectRepository } from '../../infrastructure/database/repositories/SubjectRepository';
import { SemesterRepository } from '../../infrastructure/database/repositories/SemesterRepository';

export class SubjectController {
  private subjectRepository: SubjectRepository;
  private semesterRepository: SemesterRepository;

  constructor() {
    this.subjectRepository = new SubjectRepository();
    this.semesterRepository = new SemesterRepository();
  }

  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const createSubject = new CreateSubject(this.subjectRepository, this.semesterRepository);
      const userId = req.userId!; // Set by authenticate middleware

      const subject = await createSubject.execute(userId, req.body);

      res.status(201).json({
        success: true,
        message: 'Subject created successfully',
        data: subject,
      });
    } catch (error) {
      next(error);
    }
  }

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getAllSubjects = new GetAllSubjects(this.subjectRepository);
      const userId = req.userId!;

      const subjects = await getAllSubjects.execute(userId);

      res.status(200).json({
        success: true,
        message: 'Subjects retrieved successfully',
        data: subjects,
      });
    } catch (error) {
      next(error);
    }
  }

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const updateSubject = new UpdateSubject(this.subjectRepository);
      const userId = req.userId!;
      const { id } = req.params;

      const subject = await updateSubject.execute(userId, id, req.body);

      res.status(200).json({
        success: true,
        message: 'Subject updated successfully',
        data: subject,
      });
    } catch (error) {
      next(error);
    }
  }

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const deleteSubject = new DeleteSubject(this.subjectRepository);
      const userId = req.userId!;
      const { id } = req.params;

      await deleteSubject.execute(userId, id);

      res.status(200).json({
        success: true,
        message: 'Subject deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }
}

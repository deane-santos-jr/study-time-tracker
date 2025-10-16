import { Request, Response, NextFunction } from 'express';
import { GetAnalytics } from '../../application/use-cases/analytics/GetAnalytics';
import { IStudySessionRepository } from '../../domain/interfaces/IStudySessionRepository';
import { ISubjectRepository } from '../../domain/interfaces/ISubjectRepository';

export class AnalyticsController {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private subjectRepository: ISubjectRepository
  ) {}

  async getAnalytics(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { startDate, endDate, subjectId } = req.query;

      const query: any = {};
      if (startDate) {
        const start = new Date(startDate as string);
        start.setHours(0, 0, 0, 0); // Set to start of day
        query.startDate = start;
      }
      if (endDate) {
        const end = new Date(endDate as string);
        end.setHours(23, 59, 59, 999); // Set to end of day
        query.endDate = end;
      }
      if (subjectId) {
        query.subjectId = subjectId as string;
      }

      const getAnalytics = new GetAnalytics(this.sessionRepository, this.subjectRepository);
      const analytics = await getAnalytics.execute(req.userId!, query);

      res.status(200).json({
        success: true,
        data: analytics,
      });
    } catch (error) {
      next(error);
    }
  }
}

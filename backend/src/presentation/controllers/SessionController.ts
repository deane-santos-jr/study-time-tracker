import { Request, Response, NextFunction } from 'express';
import { StartSession } from '../../application/use-cases/session/StartSession';
import { PauseSession } from '../../application/use-cases/session/PauseSession';
import { ResumeSession } from '../../application/use-cases/session/ResumeSession';
import { StopSession } from '../../application/use-cases/session/StopSession';
import { GetActiveSession } from '../../application/use-cases/session/GetActiveSession';
import { GetAllSessions } from '../../application/use-cases/session/GetAllSessions';
import { StudySessionRepository } from '../../infrastructure/database/repositories/StudySessionRepository';
import { SubjectRepository } from '../../infrastructure/database/repositories/SubjectRepository';
import { BreakRepository } from '../../infrastructure/database/repositories/BreakRepository';

export class SessionController {
  private sessionRepository: StudySessionRepository;
  private subjectRepository: SubjectRepository;
  private breakRepository: BreakRepository;

  constructor() {
    this.sessionRepository = new StudySessionRepository();
    this.subjectRepository = new SubjectRepository();
    this.breakRepository = new BreakRepository();
  }

  async start(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const startSession = new StartSession(
        this.sessionRepository,
        this.subjectRepository
      );
      const userId = req.userId!;

      const session = await startSession.execute(userId, req.body);

      res.status(201).json({
        success: true,
        message: 'Session started successfully',
        data: session,
      });
    } catch (error) {
      next(error);
    }
  }

  async pause(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pauseSession = new PauseSession(this.sessionRepository, this.breakRepository);
      const userId = req.userId!;
      const { id } = req.params;

      const session = await pauseSession.execute(userId, id);

      res.status(200).json({
        success: true,
        message: 'Session paused successfully',
        data: session,
      });
    } catch (error) {
      next(error);
    }
  }

  async resume(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const resumeSession = new ResumeSession(this.sessionRepository, this.breakRepository);
      const userId = req.userId!;
      const { id } = req.params;

      const session = await resumeSession.execute(userId, id);

      res.status(200).json({
        success: true,
        message: 'Session resumed successfully',
        data: session,
      });
    } catch (error) {
      next(error);
    }
  }

  async stop(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stopSession = new StopSession(this.sessionRepository, this.breakRepository);
      const userId = req.userId!;
      const { id } = req.params;

      const session = await stopSession.execute(userId, id);

      res.status(200).json({
        success: true,
        message: 'Session stopped successfully',
        data: session,
      });
    } catch (error) {
      next(error);
    }
  }

  async getActive(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getActiveSession = new GetActiveSession(this.sessionRepository);
      const userId = req.userId!;

      const session = await getActiveSession.execute(userId);

      res.status(200).json({
        success: true,
        message: session ? 'Active session found' : 'No active session',
        data: session,
      });
    } catch (error) {
      next(error);
    }
  }

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getAllSessions = new GetAllSessions(this.sessionRepository);
      const userId = req.userId!;

      const sessions = await getAllSessions.execute(userId);

      res.status(200).json({
        success: true,
        message: 'Sessions retrieved successfully',
        data: sessions,
      });
    } catch (error) {
      next(error);
    }
  }
}

import { Router } from 'express';
import { AnalyticsController } from '../controllers/AnalyticsController';
import { authenticate } from '../middlewares/authenticate';
import { StudySessionRepository } from '../../infrastructure/database/repositories/StudySessionRepository';
import { SubjectRepository } from '../../infrastructure/database/repositories/SubjectRepository';

const router = Router();

const sessionRepository = new StudySessionRepository();
const subjectRepository = new SubjectRepository();

const analyticsController = new AnalyticsController(sessionRepository, subjectRepository);

router.use(authenticate);

router.get('/', analyticsController.getAnalytics.bind(analyticsController));

export default router;

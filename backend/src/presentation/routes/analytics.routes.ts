import { Router } from 'express';
import { AnalyticsController } from '../controllers/AnalyticsController';
import { authenticate } from '../middlewares/authenticate';
import { StudySessionRepository } from '../../infrastructure/database/repositories/StudySessionRepository';
import { SubjectRepository } from '../../infrastructure/database/repositories/SubjectRepository';

const router = Router();

// Initialize repositories
const sessionRepository = new StudySessionRepository();
const subjectRepository = new SubjectRepository();

// Initialize controller
const analyticsController = new AnalyticsController(sessionRepository, subjectRepository);

// Apply auth middleware to all routes
router.use(authenticate);

// Analytics routes
router.get('/', analyticsController.getAnalytics.bind(analyticsController));

export default router;

import { Router } from 'express';
import { SessionController } from '../controllers/SessionController';
import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validator';
import { z } from 'zod';

const router = Router();
const sessionController = new SessionController();

// Validation schemas
const startSessionSchema = z.object({
  subjectId: z.string().uuid('Invalid subject ID'),
  semesterId: z.string().uuid().optional(),
});

// All routes require authentication
router.use(authenticate);

// Routes
router.post('/start', validate(startSessionSchema), sessionController.start.bind(sessionController));
router.post('/:id/pause', sessionController.pause.bind(sessionController));
router.post('/:id/resume', sessionController.resume.bind(sessionController));
router.post('/:id/stop', sessionController.stop.bind(sessionController));
router.get('/active', sessionController.getActive.bind(sessionController));
router.get('/', sessionController.getAll.bind(sessionController));
router.delete('/:id', sessionController.delete.bind(sessionController));

export default router;

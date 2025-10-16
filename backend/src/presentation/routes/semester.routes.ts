import { Router } from 'express';
import { SemesterController } from '../controllers/SemesterController';
import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validator';
import { z } from 'zod';

const router = Router();
const semesterController = new SemesterController();

// Validation schemas
const createSemesterSchema = z.object({
  name: z.string().min(1, 'Semester name is required').max(100, 'Name too long'),
  startDate: z.string().or(z.date()).refine((val) => !isNaN(Date.parse(val.toString())), {
    message: 'Invalid start date',
  }),
  endDate: z.string().or(z.date()).refine((val) => !isNaN(Date.parse(val.toString())), {
    message: 'Invalid end date',
  }),
});

const updateSemesterSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  startDate: z.string().or(z.date()).refine((val) => !isNaN(Date.parse(val.toString())), {
    message: 'Invalid start date',
  }).optional(),
  endDate: z.string().or(z.date()).refine((val) => !isNaN(Date.parse(val.toString())), {
    message: 'Invalid end date',
  }).optional(),
  isActive: z.boolean().optional(),
});

// All routes require authentication
router.use(authenticate);

// Routes
router.post('/', validate(createSemesterSchema), semesterController.create.bind(semesterController));
router.get('/', semesterController.getAll.bind(semesterController));
router.get('/active', semesterController.getActive.bind(semesterController));
router.put('/:id', validate(updateSemesterSchema), semesterController.update.bind(semesterController));
router.delete('/:id', semesterController.delete.bind(semesterController));

export default router;

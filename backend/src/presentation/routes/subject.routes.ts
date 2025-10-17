import { Router } from 'express';
import { SubjectController } from '../controllers/SubjectController';
import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validator';
import { z } from 'zod';

const router = Router();
const subjectController = new SubjectController();

const createSubjectSchema = z.object({
  name: z.string().min(1, 'Subject name is required').max(100, 'Name too long'),
  color: z.string().regex(/^#[0-9A-F]{6}$/i, 'Invalid hex color (e.g., #FF5733)'),
  icon: z.string().optional(),
  semesterId: z.string().min(1, 'Semester ID is required'),
});

const updateSubjectSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  color: z.string().regex(/^#[0-9A-F]{6}$/i).optional(),
  icon: z.string().optional(),
});

router.use(authenticate);

router.post('/', validate(createSubjectSchema), subjectController.create.bind(subjectController));
router.get('/', subjectController.getAll.bind(subjectController));
router.put('/:id', validate(updateSubjectSchema), subjectController.update.bind(subjectController));
router.delete('/:id', subjectController.delete.bind(subjectController));

export default router;

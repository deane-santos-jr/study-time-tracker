import { Router } from 'express';
import { NoteController } from '../controllers/NoteController';
import { authenticate } from '../middlewares/authenticate';
import { NoteRepository } from '../../infrastructure/database/repositories/NoteRepository';
import { StudySessionRepository } from '../../infrastructure/database/repositories/StudySessionRepository';

const router = Router();
const noteRepository = new NoteRepository();
const sessionRepository = new StudySessionRepository();
const noteController = new NoteController(noteRepository, sessionRepository);

// All routes require authentication
router.use(authenticate);

// Create note for a session
router.post('/', (req, res, next) => noteController.create(req, res, next));

// Get note by session ID
router.get('/session/:sessionId', (req, res, next) => noteController.getBySession(req, res, next));

// Update note
router.put('/:id', (req, res, next) => noteController.update(req, res, next));

// Delete note
router.delete('/:id', (req, res, next) => noteController.delete(req, res, next));

export default router;

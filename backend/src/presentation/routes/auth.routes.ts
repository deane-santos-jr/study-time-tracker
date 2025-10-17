import { Router } from 'express';
import { AuthController } from '../controllers/AuthController';
import { authenticate } from '../middlewares/authenticate';
import { validate } from '../middlewares/validator';
import { z } from 'zod';

const router = Router();
const authController = new AuthController();

const registerSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  firstName: z.string().min(1, 'First name is required'),
  lastName: z.string().min(1, 'Last name is required'),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(1, 'Password is required'),
});

const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

router.post(
  '/register',
  validate(registerSchema),
  authController.register.bind(authController)
);

router.post(
  '/login',
  validate(loginSchema),
  authController.login.bind(authController)
);

router.post(
  '/refresh',
  validate(refreshTokenSchema),
  authController.refreshToken.bind(authController)
);

router.get('/profile', authenticate, authController.getProfile.bind(authController));

router.post('/logout', authenticate, authController.logout.bind(authController));

export default router;

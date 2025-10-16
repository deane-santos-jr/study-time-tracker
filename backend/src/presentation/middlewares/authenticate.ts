import { Request, Response, NextFunction } from 'express';
import { JWTService } from '../../infrastructure/security/JWTService';
import { UnauthorizedError } from '../../shared/errors/AppError';

// Extend Express Request type to include userId
declare global {
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

export const authenticate = (req: Request, _res: Response, next: NextFunction) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedError('No token provided');
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token
    const jwtService = new JWTService();
    const payload = jwtService.verifyToken(token);

    if (!payload) {
      throw new UnauthorizedError('Invalid or expired token');
    }

    // Attach userId to request
    req.userId = payload.userId;

    next();
  } catch (error) {
    if (error instanceof UnauthorizedError) {
      next(error);
    } else {
      next(new UnauthorizedError('Authentication failed'));
    }
  }
};

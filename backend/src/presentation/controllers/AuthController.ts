import { Request, Response, NextFunction } from 'express';
import { RegisterUser } from '../../application/use-cases/auth/RegisterUser';
import { LoginUser } from '../../application/use-cases/auth/LoginUser';
import { RefreshToken } from '../../application/use-cases/auth/RefreshToken';
import { GetUserProfile } from '../../application/use-cases/auth/GetUserProfile';
import { UserRepository } from '../../infrastructure/database/repositories/UserRepository';
import { PasswordHashingService } from '../../infrastructure/security/PasswordHashingService';
import { JWTService } from '../../infrastructure/security/JWTService';

export class AuthController {
  private userRepository: UserRepository;
  private passwordHashingService: PasswordHashingService;
  private jwtService: JWTService;

  constructor() {
    this.userRepository = new UserRepository();
    this.passwordHashingService = new PasswordHashingService();
    this.jwtService = new JWTService();
  }

  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const registerUser = new RegisterUser(
        this.userRepository,
        this.passwordHashingService
      );

      const user = await registerUser.execute(req.body);

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        data: {
          id: user.id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          createdAt: user.createdAt,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const loginUser = new LoginUser(
        this.userRepository,
        this.passwordHashingService,
        this.jwtService
      );

      const result = await loginUser.execute(req.body);

      res.status(200).json({
        success: true,
        message: 'Login successful',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async refreshToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const refreshToken = new RefreshToken(this.jwtService, this.userRepository);

      const result = await refreshToken.execute(req.body);

      res.status(200).json({
        success: true,
        message: 'Token refreshed successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  async getProfile(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const getUserProfile = new GetUserProfile(this.userRepository);

      const userId = req.userId!; // Set by authenticate middleware
      const user = await getUserProfile.execute(userId);

      res.status(200).json({
        success: true,
        message: 'Profile retrieved successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  async logout(_req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // For JWT, logout is handled client-side by removing the token
      // If you implement token blacklisting, add logic here

      res.status(200).json({
        success: true,
        message: 'Logout successful',
      });
    } catch (error) {
      next(error);
    }
  }
}

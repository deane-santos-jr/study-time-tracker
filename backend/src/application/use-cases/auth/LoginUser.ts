import { IUserRepository } from '../../../domain/repositories/IUserRepository';
import { PasswordHashingService } from '../../../infrastructure/security/PasswordHashingService';
import { JWTService, TokenPayload } from '../../../infrastructure/security/JWTService';
import { UnauthorizedError, ValidationError } from '../../../shared/errors/AppError';

export interface LoginUserDTO {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  user: {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
  };
}

export class LoginUser {
  constructor(
    private userRepository: IUserRepository,
    private passwordHashingService: PasswordHashingService,
    private jwtService: JWTService
  ) {}

  async execute(dto: LoginUserDTO): Promise<LoginResponse> {
    // Validate input
    this.validateInput(dto);

    // Find user by email
    const user = await this.userRepository.findByEmail(dto.email.toLowerCase());
    if (!user) {
      throw new UnauthorizedError('Invalid email or password');
    }

    // Check if user is active
    if (!user.isActive) {
      throw new UnauthorizedError('Account is inactive');
    }

    // Verify password
    const isPasswordValid = await this.passwordHashingService.compare(
      dto.password,
      user.password
    );

    if (!isPasswordValid) {
      throw new UnauthorizedError('Invalid email or password');
    }

    // Generate tokens
    const tokenPayload: TokenPayload = {
      userId: user.id,
      email: user.email,
    };

    const token = this.jwtService.generateToken(tokenPayload);
    const refreshToken = this.jwtService.generateRefreshToken(tokenPayload);

    return {
      token,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
      },
    };
  }

  private validateInput(dto: LoginUserDTO): void {
    if (!dto.email || dto.email.trim().length === 0) {
      throw new ValidationError('Email is required');
    }

    if (!dto.password || dto.password.trim().length === 0) {
      throw new ValidationError('Password is required');
    }
  }
}

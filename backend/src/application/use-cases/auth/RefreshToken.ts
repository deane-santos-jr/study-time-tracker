import { JWTService } from '../../../infrastructure/security/JWTService';
import { IUserRepository } from '../../../domain/repositories/IUserRepository';
import { UnauthorizedError } from '../../../shared/errors/AppError';

export interface RefreshTokenDTO {
  refreshToken: string;
}

export interface RefreshTokenResponse {
  token: string;
  refreshToken: string;
}

export class RefreshToken {
  constructor(
    private jwtService: JWTService,
    private userRepository: IUserRepository
  ) {}

  async execute(dto: RefreshTokenDTO): Promise<RefreshTokenResponse> {
    const payload = this.jwtService.verifyRefreshToken(dto.refreshToken);

    if (!payload) {
      throw new UnauthorizedError('Invalid refresh token');
    }

    const user = await this.userRepository.findById(payload.userId);

    if (!user || !user.isActive) {
      throw new UnauthorizedError('User not found or inactive');
    }

    const tokenPayload = {
      userId: user.id,
      email: user.email,
    };

    const newToken = this.jwtService.generateToken(tokenPayload);
    const newRefreshToken = this.jwtService.generateRefreshToken(tokenPayload);

    return {
      token: newToken,
      refreshToken: newRefreshToken,
    };
  }
}

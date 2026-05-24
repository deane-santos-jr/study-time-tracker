import { IUserRepository } from '../../../domain/repositories/IUserRepository';
import { PasswordHashingService } from '../../../infrastructure/security/PasswordHashingService';
import {
  NotFoundError,
  UnauthorizedError,
  ValidationError,
} from '../../../shared/errors/AppError';

export interface DeleteAccountDTO {
  password: string;
}

export class DeleteAccount {
  constructor(
    private userRepository: IUserRepository,
    private passwordHashingService: PasswordHashingService
  ) {}

  async execute(userId: string, dto: DeleteAccountDTO): Promise<void> {
    if (!dto.password || dto.password.trim().length === 0) {
      throw new ValidationError('Password is required to delete your account');
    }

    const user = await this.userRepository.findById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    const ok = await this.passwordHashingService.compare(
      dto.password,
      user.password
    );
    if (!ok) {
      throw new UnauthorizedError('Password does not match');
    }

    await this.userRepository.delete(userId);
  }
}

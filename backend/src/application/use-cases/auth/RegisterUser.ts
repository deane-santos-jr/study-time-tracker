import { v4 as uuidv4 } from 'uuid';
import { User } from '../../../domain/entities/User';
import { IUserRepository } from '../../../domain/repositories/IUserRepository';
import { PasswordHashingService } from '../../../infrastructure/security/PasswordHashingService';
import { ValidationError, ConflictError } from '../../../shared/errors/AppError';

export interface RegisterUserDTO {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export class RegisterUser {
  constructor(
    private userRepository: IUserRepository,
    private passwordHashingService: PasswordHashingService
  ) {}

  async execute(dto: RegisterUserDTO): Promise<User> {
    this.validateInput(dto);

    const existingUser = await this.userRepository.findByEmail(dto.email);
    if (existingUser) {
      throw new ConflictError('User with this email already exists');
    }

    const passwordValidation = await this.passwordHashingService.validatePasswordStrength(
      dto.password
    );
    if (!passwordValidation.isValid) {
      throw new ValidationError(passwordValidation.errors.join(', '));
    }

    const hashedPassword = await this.passwordHashingService.hash(dto.password);

    const user = User.create(
      uuidv4(),
      dto.email.toLowerCase(),
      hashedPassword,
      dto.firstName,
      dto.lastName
    );

    return await this.userRepository.create(user);
  }

  private validateInput(dto: RegisterUserDTO): void {
    if (!dto.email || !this.isValidEmail(dto.email)) {
      throw new ValidationError('Invalid email address');
    }

    if (!dto.password) {
      throw new ValidationError('Password is required');
    }

    if (!dto.firstName || dto.firstName.trim().length === 0) {
      throw new ValidationError('First name is required');
    }

    if (!dto.lastName || dto.lastName.trim().length === 0) {
      throw new ValidationError('Last name is required');
    }
  }

  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}

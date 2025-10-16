import { Repository } from 'typeorm';
import { AppDataSource } from '../../config/database.config';
import { UserEntity } from '../entities/UserEntity';
import { IUserRepository } from '../../../domain/repositories/IUserRepository';
import { User } from '../../../domain/entities/User';

export class UserRepository implements IUserRepository {
  private repository: Repository<UserEntity>;

  constructor() {
    this.repository = AppDataSource.getRepository(UserEntity);
  }

  async create(user: User): Promise<User> {
    const userEntity = this.repository.create({
      id: user.id,
      email: user.email,
      password: user.password,
      firstName: user.firstName,
      lastName: user.lastName,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    });

    const saved = await this.repository.save(userEntity);
    return this.toDomain(saved);
  }

  async findById(id: string): Promise<User | null> {
    const userEntity = await this.repository.findOne({ where: { id } });
    return userEntity ? this.toDomain(userEntity) : null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const userEntity = await this.repository.findOne({
      where: { email: email.toLowerCase() },
    });
    return userEntity ? this.toDomain(userEntity) : null;
  }

  async update(user: User): Promise<User> {
    await this.repository.update(user.id, {
      email: user.email,
      password: user.password,
      firstName: user.firstName,
      lastName: user.lastName,
      isActive: user.isActive,
      updatedAt: new Date(),
    });

    const updated = await this.repository.findOne({ where: { id: user.id } });
    if (!updated) {
      throw new Error('User not found after update');
    }

    return this.toDomain(updated);
  }

  async delete(id: string): Promise<void> {
    await this.repository.delete(id);
  }

  private toDomain(entity: UserEntity): User {
    return new User(
      entity.id,
      entity.email,
      entity.password,
      entity.firstName,
      entity.lastName,
      entity.isActive,
      entity.createdAt,
      entity.updatedAt
    );
  }
}

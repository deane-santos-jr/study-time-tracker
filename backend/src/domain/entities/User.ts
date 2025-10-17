export class User {
  constructor(
    public readonly id: string,
    public email: string,
    public password: string, 
    public firstName: string,
    public lastName: string,
    public isActive: boolean,
    public readonly createdAt: Date,
    public updatedAt: Date
  ) {}

  updateProfile(firstName: string, lastName: string): void {
    this.firstName = firstName;
    this.lastName = lastName;
    this.updatedAt = new Date();
  }

  deactivate(): void {
    this.isActive = false;
    this.updatedAt = new Date();
  }

  activate(): void {
    this.isActive = true;
    this.updatedAt = new Date();
  }

  getFullName(): string {
    return `${this.firstName} ${this.lastName}`;
  }

  static create(
    id: string,
    email: string,
    password: string,
    firstName: string,
    lastName: string
  ): User {
    return new User(
      id,
      email,
      password,
      firstName,
      lastName,
      true,
      new Date(),
      new Date()
    );
  }
}

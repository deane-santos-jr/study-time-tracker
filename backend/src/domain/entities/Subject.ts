export class Subject {
  constructor(
    public readonly id: string,
    public readonly userId: string,
    public readonly semesterId: string,
    public name: string,
    public color: string,
    public icon: string | undefined,
    public isActive: boolean,
    public readonly createdAt: Date,
    public updatedAt: Date
  ) {}

  updateDetails(name: string, color: string, icon?: string): void {
    this.name = name;
    this.color = color;
    this.icon = icon;
    this.updatedAt = new Date();
  }

  updateName(name: string): void {
    this.name = name;
    this.updatedAt = new Date();
  }

  updateColor(color: string): void {
    this.color = color;
    this.updatedAt = new Date();
  }

  updateIcon(icon: string): void {
    this.icon = icon;
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

  belongsToUser(userId: string): boolean {
    return this.userId === userId;
  }

  static create(
    id: string,
    userId: string,
    semesterId: string,
    name: string,
    color: string,
    icon?: string
  ): Subject {
    return new Subject(
      id,
      userId,
      semesterId,
      name,
      color,
      icon,
      true,
      new Date(),
      new Date()
    );
  }
}

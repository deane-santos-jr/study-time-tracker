export class Semester {
  constructor(
    public readonly id: string,
    public readonly userId: string,
    public name: string,
    public startDate: Date,
    public endDate: Date,
    public isActive: boolean,
    public readonly createdAt: Date,
    public updatedAt: Date
  ) {}

  isWithinSemester(date: Date): boolean {
    return date >= this.startDate && date <= this.endDate;
  }

  activate(): void {
    this.isActive = true;
    this.updatedAt = new Date();
  }

  deactivate(): void {
    this.isActive = false;
    this.updatedAt = new Date();
  }

  belongsToUser(userId: string): boolean {
    return this.userId === userId;
  }

  static create(
    id: string,
    userId: string,
    name: string,
    startDate: Date,
    endDate: Date
  ): Semester {
    if (startDate >= endDate) {
      throw new Error('Start date must be before end date');
    }

    return new Semester(
      id,
      userId,
      name,
      startDate,
      endDate,
      false,
      new Date(),
      new Date()
    );
  }
}

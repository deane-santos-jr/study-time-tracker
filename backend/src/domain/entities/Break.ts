export class Break {
  constructor(
    public readonly id: string,
    public readonly sessionId: string,
    public readonly startTime: Date,
    public endTime: Date | undefined,
    public duration: number | undefined, // in seconds
    public readonly createdAt: Date
  ) {}

  end(): void {
    if (this.endTime) {
      throw new Error('Break already ended');
    }

    this.endTime = new Date();
    this.duration = this.getDuration();
  }

  getDuration(): number {
    if (!this.endTime) {
      // Calculate current duration if still ongoing
      const now = new Date();
      return Math.floor((now.getTime() - this.startTime.getTime()) / 1000);
    }
    return Math.floor((this.endTime.getTime() - this.startTime.getTime()) / 1000);
  }

  static create(id: string, sessionId: string): Break {
    return new Break(
      id,
      sessionId,
      new Date(),
      undefined,
      undefined,
      new Date()
    );
  }
}

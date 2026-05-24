export enum SessionStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
}

export class StudySession {
  constructor(
    public readonly id: string,
    public readonly userId: string,
    public subjectId: string | null,
    public semesterId: string | null,
    public activityName: string | null,
    public readonly startTime: Date,
    public endTime: Date | undefined,
    public pausedAt: Date | undefined,
    public status: SessionStatus,
    public totalDuration: number | undefined,
    public effectiveStudyTime: number | undefined,
    public breakCount: number,
    public accumulatedPauseTime: number,
    public readonly createdAt: Date,
    public updatedAt: Date
  ) {
    // Invariant: exactly one of (subjectId, activityName) is non-null.
    const hasSubject = subjectId !== null;
    const hasActivity = activityName !== null;
    if (hasSubject === hasActivity) {
      throw new Error(
        'StudySession must have exactly one of subjectId or activityName'
      );
    }
  }

  pause(): void {
    if (this.status !== SessionStatus.ACTIVE) {
      throw new Error('Can only pause an active session');
    }
    this.status = SessionStatus.PAUSED;
    this.pausedAt = new Date();
    this.updatedAt = new Date();
  }

  resume(): void {
    if (this.status !== SessionStatus.PAUSED) {
      throw new Error('Can only resume a paused session');
    }
    this.status = SessionStatus.ACTIVE;
    this.pausedAt = undefined;
    this.updatedAt = new Date();
  }

  stop(totalBreakTimeInSeconds: number = 0, totalPauseTimeInSeconds: number = 0): void {
    if (this.status === SessionStatus.COMPLETED) {
      throw new Error('Session already completed');
    }
    this.endTime = new Date();
    this.status = SessionStatus.COMPLETED;
    this.totalDuration = Math.floor((this.endTime.getTime() - this.startTime.getTime()) / 1000);
    this.effectiveStudyTime = this.totalDuration - totalBreakTimeInSeconds - totalPauseTimeInSeconds;
    this.updatedAt = new Date();
  }

  getCurrentDuration(): number {
    const endTime = this.endTime || new Date();
    return Math.floor((endTime.getTime() - this.startTime.getTime()) / 1000);
  }

  isActive(): boolean {
    return this.status === SessionStatus.ACTIVE;
  }

  belongsToUser(userId: string): boolean {
    return this.userId === userId;
  }

  isAdHoc(): boolean {
    return this.subjectId === null;
  }

  orphanToAdHoc(activityName: string): void {
    if (this.subjectId === null) {
      throw new Error('Session is already ad-hoc');
    }
    this.subjectId = null;
    this.semesterId = null;
    this.activityName = activityName;
    this.updatedAt = new Date();
  }

  static createForSubject(
    id: string,
    userId: string,
    subjectId: string,
    semesterId: string
  ): StudySession {
    return new StudySession(
      id,
      userId,
      subjectId,
      semesterId,
      null,
      new Date(),
      undefined,
      undefined,
      SessionStatus.ACTIVE,
      undefined,
      undefined,
      0,
      0,
      new Date(),
      new Date()
    );
  }

  static createAdHoc(
    id: string,
    userId: string,
    activityName: string
  ): StudySession {
    return new StudySession(
      id,
      userId,
      null,
      null,
      activityName,
      new Date(),
      undefined,
      undefined,
      SessionStatus.ACTIVE,
      undefined,
      undefined,
      0,
      0,
      new Date(),
      new Date()
    );
  }
}

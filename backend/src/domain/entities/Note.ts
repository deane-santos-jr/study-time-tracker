export class Note {
  constructor(
    public readonly id: string,
    public readonly sessionId: string,
    public readonly userId: string,
    public content: string,
    public topics: string | undefined,
    public difficultyLevel: number | undefined, // 1-5 scale
    public focusLevel: number | undefined, // 1-5 scale
    public readonly createdAt: Date,
    public updatedAt: Date
  ) {}

  update(
    content?: string,
    topics?: string,
    difficultyLevel?: number,
    focusLevel?: number
  ): void {
    if (content !== undefined) this.content = content;
    if (topics !== undefined) this.topics = topics;
    if (difficultyLevel !== undefined) this.difficultyLevel = difficultyLevel;
    if (focusLevel !== undefined) this.focusLevel = focusLevel;
    this.updatedAt = new Date();
  }

  static create(
    id: string,
    sessionId: string,
    userId: string,
    content: string,
    topics?: string,
    difficultyLevel?: number,
    focusLevel?: number
  ): Note {
    return new Note(
      id,
      sessionId,
      userId,
      content,
      topics,
      difficultyLevel,
      focusLevel,
      new Date(),
      new Date()
    );
  }

  belongsToUser(userId: string): boolean {
    return this.userId === userId;
  }
}

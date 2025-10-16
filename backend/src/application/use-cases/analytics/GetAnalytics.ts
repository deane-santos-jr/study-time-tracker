import { IStudySessionRepository } from '../../../domain/interfaces/IStudySessionRepository';
import { ISubjectRepository } from '../../../domain/interfaces/ISubjectRepository';

interface AnalyticsQuery {
  startDate?: Date;
  endDate?: Date;
  subjectId?: string;
}

interface SubjectStats {
  subjectId: string;
  subjectName: string;
  totalTime: number;
  sessionCount: number;
  averageSessionDuration: number;
}

interface DailyStats {
  date: string;
  totalTime: number;
  sessionCount: number;
}

interface AnalyticsResponse {
  totalStudyTime: number;
  totalEffectiveTime: number;
  totalBreakTime: number;
  totalSessions: number;
  averageSessionDuration: number;
  subjectStats: SubjectStats[];
  dailyStats: DailyStats[];
}

export class GetAnalytics {
  constructor(
    private sessionRepository: IStudySessionRepository,
    private subjectRepository: ISubjectRepository
  ) {}

  async execute(userId: string, query: AnalyticsQuery): Promise<AnalyticsResponse> {
    // Get all completed sessions for the user
    let sessions = await this.sessionRepository.findByUserId(userId);

    // Filter by date range if provided
    if (query.startDate) {
      sessions = sessions.filter(
        (session) => new Date(session.startTime) >= query.startDate!
      );
    }
    if (query.endDate) {
      sessions = sessions.filter(
        (session) => new Date(session.startTime) <= query.endDate!
      );
    }

    // Filter by subject if provided
    if (query.subjectId) {
      sessions = sessions.filter((session) => session.subjectId === query.subjectId);
    }

    // Only include completed sessions
    const completedSessions = sessions.filter((session) => session.status === 'COMPLETED');

    // Calculate total stats
    const totalStudyTime = completedSessions.reduce(
      (sum, session) => sum + (session.totalDuration || 0),
      0
    );
    const totalEffectiveTime = completedSessions.reduce(
      (sum, session) => sum + (session.effectiveStudyTime || 0),
      0
    );
    const totalBreakTime = totalStudyTime - totalEffectiveTime;
    const totalSessions = completedSessions.length;
    const averageSessionDuration = totalSessions > 0 ? totalEffectiveTime / totalSessions : 0;

    // Calculate subject stats
    const subjectMap = new Map<string, { totalTime: number; count: number }>();
    for (const session of completedSessions) {
      const current = subjectMap.get(session.subjectId) || { totalTime: 0, count: 0 };
      subjectMap.set(session.subjectId, {
        totalTime: current.totalTime + (session.effectiveStudyTime || 0),
        count: current.count + 1,
      });
    }

    // Get subject details
    const subjects = await this.subjectRepository.findByUserId(userId);
    const subjectStats: SubjectStats[] = [];
    for (const [subjectId, stats] of subjectMap.entries()) {
      const subject = subjects.find((s) => s.id === subjectId);
      if (subject) {
        subjectStats.push({
          subjectId,
          subjectName: subject.name,
          totalTime: stats.totalTime,
          sessionCount: stats.count,
          averageSessionDuration: stats.totalTime / stats.count,
        });
      }
    }

    // Calculate daily stats
    const dailyMap = new Map<string, { totalTime: number; count: number }>();
    for (const session of completedSessions) {
      const dateKey = new Date(session.startTime).toISOString().split('T')[0];
      const current = dailyMap.get(dateKey) || { totalTime: 0, count: 0 };
      dailyMap.set(dateKey, {
        totalTime: current.totalTime + (session.effectiveStudyTime || 0),
        count: current.count + 1,
      });
    }

    const dailyStats: DailyStats[] = Array.from(dailyMap.entries())
      .map(([date, stats]) => ({
        date,
        totalTime: stats.totalTime,
        sessionCount: stats.count,
      }))
      .sort((a, b) => a.date.localeCompare(b.date));

    return {
      totalStudyTime,
      totalEffectiveTime,
      totalBreakTime,
      totalSessions,
      averageSessionDuration,
      subjectStats,
      dailyStats,
    };
  }
}

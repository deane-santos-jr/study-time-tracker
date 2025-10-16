import { apiService } from './api';

export interface SubjectStats {
  subjectId: string;
  subjectName: string;
  totalTime: number;
  sessionCount: number;
  averageSessionDuration: number;
}

export interface DailyStats {
  date: string;
  totalTime: number;
  sessionCount: number;
}

export interface AnalyticsData {
  totalStudyTime: number;
  totalEffectiveTime: number;
  totalBreakTime: number;
  totalSessions: number;
  averageSessionDuration: number;
  subjectStats: SubjectStats[];
  dailyStats: DailyStats[];
}

export interface AnalyticsQuery {
  startDate?: string;
  endDate?: string;
  subjectId?: string;
}

export const analyticsService = {
  async getAnalytics(query?: AnalyticsQuery): Promise<AnalyticsData> {
    const params = new URLSearchParams();
    if (query?.startDate) {
      params.append('startDate', query.startDate);
    }
    if (query?.endDate) {
      params.append('endDate', query.endDate);
    }
    if (query?.subjectId) {
      params.append('subjectId', query.subjectId);
    }

    const queryString = params.toString();
    const url = queryString ? `/analytics?${queryString}` : '/analytics';

    const response = await apiService.get<AnalyticsData>(url);
    return response.data!;
  },
};

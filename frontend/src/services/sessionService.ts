import { apiService } from './api';
import type { StudySession, StartSessionData, ApiResponse } from '../types';

export const sessionService = {
  async start(data: StartSessionData): Promise<StudySession> {
    const response = await apiService.post<StudySession>('/sessions/start', data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to start session');
  },

  async pause(sessionId: string, isBreak: boolean = true): Promise<StudySession> {
    const response = await apiService.post<StudySession>(`/sessions/${sessionId}/pause`, { isBreak });
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to pause session');
  },

  async resume(sessionId: string): Promise<StudySession> {
    const response = await apiService.post<StudySession>(`/sessions/${sessionId}/resume`);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to resume session');
  },

  async stop(sessionId: string): Promise<StudySession> {
    const response = await apiService.post<StudySession>(`/sessions/${sessionId}/stop`);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to stop session');
  },

  async getActive(): Promise<StudySession | null> {
    const response = await apiService.get<StudySession | null>('/sessions/active');
    return response.data || null;
  },

  async getAll(): Promise<StudySession[]> {
    const response = await apiService.get<StudySession[]>('/sessions');
    return response.data || [];
  },

  async delete(sessionId: string): Promise<void> {
    await apiService.delete(`/sessions/${sessionId}`);
  },
};

import { apiService } from './api';
import type { Semester, CreateSemesterData, UpdateSemesterData } from '../types';

export const semesterService = {
  async getAll(): Promise<Semester[]> {
    const response = await apiService.get<Semester[]>('/semesters');
    return response.data || [];
  },

  async getActive(): Promise<Semester | null> {
    const response = await apiService.get<Semester>('/semesters/active');
    return response.data || null;
  },

  async create(data: CreateSemesterData): Promise<Semester> {
    const response = await apiService.post<Semester>('/semesters', data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to create semester');
  },

  async update(id: string, data: UpdateSemesterData): Promise<Semester> {
    const response = await apiService.put<Semester>(`/semesters/${id}`, data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to update semester');
  },

  async delete(id: string): Promise<void> {
    await apiService.delete(`/semesters/${id}`);
  },
};

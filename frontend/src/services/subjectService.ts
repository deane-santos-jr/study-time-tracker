import { apiService } from './api';
import type { Subject, CreateSubjectData, UpdateSubjectData, ApiResponse } from '../types';

export const subjectService = {
  async getAll(): Promise<Subject[]> {
    const response = await apiService.get<Subject[]>('/subjects');
    return response.data || [];
  },

  async create(data: CreateSubjectData): Promise<Subject> {
    const response = await apiService.post<Subject>('/subjects', data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to create subject');
  },

  async update(id: string, data: UpdateSubjectData): Promise<Subject> {
    const response = await apiService.put<Subject>(`/subjects/${id}`, data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to update subject');
  },

  async delete(id: string): Promise<void> {
    await apiService.delete(`/subjects/${id}`);
  },
};

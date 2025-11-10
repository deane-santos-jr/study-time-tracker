import { apiService } from './api';
import type { Note, CreateNoteData, UpdateNoteData } from '../types';

export const noteService = {
  async create(data: CreateNoteData): Promise<Note> {
    const response = await apiService.post<Note>('/notes', data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to create note');
  },

  async getBySession(sessionId: string): Promise<Note | null> {
    const response = await apiService.get<Note | null>(`/notes/session/${sessionId}`);
    return response.data || null;
  },

  async update(noteId: string, data: UpdateNoteData): Promise<Note> {
    const response = await apiService.put<Note>(`/notes/${noteId}`, data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Failed to update note');
  },

  async delete(noteId: string): Promise<void> {
    await apiService.delete(`/notes/${noteId}`);
  },
};

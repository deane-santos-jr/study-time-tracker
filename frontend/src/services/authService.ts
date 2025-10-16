import { apiService } from './api';
import type { LoginCredentials, RegisterData, AuthResponse, User, ApiResponse } from '../types';

export const authService = {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await apiService.post<AuthResponse>('/auth/login', credentials);
    if (response.data) {
      // Store token and user data
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('refreshToken', response.data.refreshToken);
      localStorage.setItem('user', JSON.stringify(response.data.user));
      return response.data;
    }
    throw new Error('Login failed');
  },

  async register(data: RegisterData): Promise<User> {
    const response = await apiService.post<User>('/auth/register', data);
    if (response.data) {
      return response.data;
    }
    throw new Error('Registration failed');
  },

  async getProfile(): Promise<User> {
    const response = await apiService.get<User>('/auth/profile');
    if (response.data) {
      localStorage.setItem('user', JSON.stringify(response.data));
      return response.data;
    }
    throw new Error('Failed to fetch profile');
  },

  async refreshToken(): Promise<AuthResponse> {
    const refreshToken = localStorage.getItem('refreshToken');
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    const response = await apiService.post<AuthResponse>('/auth/refresh', { refreshToken });
    if (response.data) {
      localStorage.setItem('token', response.data.token);
      localStorage.setItem('refreshToken', response.data.refreshToken);
      return response.data;
    }
    throw new Error('Token refresh failed');
  },

  logout(): void {
    localStorage.removeItem('token');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
  },

  getStoredUser(): User | null {
    const userStr = localStorage.getItem('user');
    if (userStr) {
      try {
        return JSON.parse(userStr);
      } catch {
        return null;
      }
    }
    return null;
  },

  getStoredToken(): string | null {
    return localStorage.getItem('token');
  },
};

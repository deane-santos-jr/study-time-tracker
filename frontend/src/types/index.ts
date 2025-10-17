// User types
export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// Subject types
export interface Subject {
  id: string;
  userId: string;
  name: string;
  color: string;
  icon: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateSubjectData {
  name: string;
  color: string;
  icon?: string;
  semesterId: string;
}

export interface UpdateSubjectData {
  name?: string;
  color?: string;
  icon?: string;
}

// Semester types
export interface Semester {
  id: string;
  userId: string;
  name: string;
  startDate: string;
  endDate: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateSemesterData {
  name: string;
  startDate: string;
  endDate: string;
}

export interface UpdateSemesterData {
  name?: string;
  startDate?: string;
  endDate?: string;
  isActive?: boolean;
}

// Session types
export enum SessionStatus {
  ACTIVE = 'ACTIVE',
  PAUSED = 'PAUSED',
  COMPLETED = 'COMPLETED',
}

export interface StudySession {
  id: string;
  userId: string;
  subjectId: string;
  startTime: string;
  endTime?: string;
  pausedAt?: string;
  status: SessionStatus;
  totalDuration?: number;
  effectiveStudyTime?: number;
  breakCount: number;
  accumulatedBreakTime?: number;
  accumulatedPauseTime?: number;
  hasActiveBreak?: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface StartSessionData {
  subjectId: string;
}

// Auth types
export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export interface AuthResponse {
  token: string;
  refreshToken: string;
  user: User;
}

export interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
}

// API Response types
export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data?: T;
}

export interface ApiError {
  success: false;
  message: string;
  error?: string;
  stack?: string;
}

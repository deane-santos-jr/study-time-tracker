# Time Tracker Application - Architecture Design

## Table of Contents
1. [Overview](#overview)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [Design Patterns](#design-patterns)
4. [Domain Model](#domain-model)
5. [Database Schema](#database-schema)
6. [API Specifications](#api-specifications)
7. [Frontend Architecture](#frontend-architecture)
8. [Project Structure](#project-structure)
9. [Technology Stack](#technology-stack)

---

## Overview

A study time tracking application that allows students to track their study sessions by subject, with support for pausing, break tracking, and analytics across semesters.

### Core Features
- **Multi-user support** with authentication (JWT)
- Start/Stop/Pause timer functionality
- Customizable subjects
- Break tracking
- Per-semester data storage
- Visual charts for progress tracking
- **PDF export** for reports and analytics
- Analytics:
  - Average daily study time
  - Average time block before starting to read
  - Time spent per subject

---

## Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│              (React Components, UI Logic)                │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│           (Use Cases, Application Services)              │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                     Domain Layer                         │
│        (Entities, Value Objects, Business Rules)         │
└─────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                    │
│     (Database, External APIs, Frameworks, Adapters)      │
└─────────────────────────────────────────────────────────┘
```

### 1. Domain Layer (Core Business Logic)
**Entities:**
- `User` - Represents an authenticated user
- `StudySession` - Represents a single study session
- `Subject` - Represents a subject/course
- `Break` - Represents a break period during study
- `Semester` - Represents an academic semester
- `TimeBlock` - Value object for time tracking

**Business Rules:**
- Users must be authenticated to access the system
- All data (subjects, sessions, semesters) belong to a specific user
- A session must belong to a subject and a user
- A session can have multiple breaks
- Total study time = session duration - total break time
- Sessions belong to semesters
- Cannot start a new session while one is active (per user)
- Users can only access their own data

### 2. Application Layer (Use Cases)
**Authentication Use Cases:**
- `RegisterUser` - Create a new user account
- `LoginUser` - Authenticate user and generate JWT token
- `RefreshToken` - Refresh expired JWT token
- `LogoutUser` - Invalidate user session
- `GetUserProfile` - Retrieve user information
- `UpdateUserProfile` - Update user details

**Session Use Cases:**
- `StartStudySession` - Begin tracking time for a subject
- `PauseStudySession` - Pause the current session
- `ResumeStudySession` - Resume a paused session
- `EndStudySession` - Complete and save the session
- `GetSessionHistory` - Retrieve past sessions
- `DeleteSession` - Remove a session

**Break Use Cases:**
- `StartBreak` - Begin a break period
- `EndBreak` - End a break period

**Subject Use Cases:**
- `CreateSubject` - Create a new subject
- `UpdateSubject` - Modify subject details
- `DeleteSubject` - Remove a subject
- `GetUserSubjects` - List all subjects for a user

**Analytics Use Cases:**
- `GetDailyAverage` - Calculate average daily study time
- `GetSubjectStats` - Get statistics per subject
- `GetSemesterStats` - Get statistics for a semester
- `GetTimeBlockAverage` - Calculate average time blocks

**Export Use Cases:**
- `ExportSessionsToPDF` - Generate PDF report of sessions
- `ExportAnalyticsToPDF` - Generate PDF report of analytics
- `ExportSubjectReportToPDF` - Generate PDF report per subject
- `ExportSemesterReportToPDF` - Generate PDF report for semester

### 3. Infrastructure Layer
**Repositories:**
- `UserRepository` - Data access for users
- `StudySessionRepository` - Data access for sessions
- `SubjectRepository` - Data access for subjects
- `SemesterRepository` - Data access for semesters
- `BreakRepository` - Data access for breaks

**Adapters:**
- `MySQLAdapter` - Database connection and queries
- `ChartDataAdapter` - Transform data for visualization
- `PDFAdapter` - Generate PDF reports using PDFKit or Puppeteer

**Services:**
- `JWTService` - Token generation and validation
- `PasswordHashingService` - Bcrypt password hashing
- `EmailService` - Email notifications (future)

### 4. Presentation Layer
**React Components:**
- Authentication (Login, Register, Profile)
- Timer controls
- Subject management
- Session history
- Analytics dashboard
- Charts and visualizations
- PDF export buttons and dialogs

---

## Design Patterns

### 1. Repository Pattern
**Purpose:** Abstraction layer between domain and data access
**Implementation:** Interfaces in domain layer, concrete implementations in infrastructure

```typescript
interface IStudySessionRepository {
  create(session: StudySession): Promise<StudySession>;
  findById(id: string): Promise<StudySession | null>;
  findBySubject(subjectId: string): Promise<StudySession[]>;
  update(session: StudySession): Promise<StudySession>;
  delete(id: string): Promise<void>;
}
```

### 2. Factory Pattern
**Purpose:** Create complex domain objects
**Implementation:**

```typescript
class StudySessionFactory {
  static create(subjectId: string, semesterId: string): StudySession;
  static createFromData(data: StudySessionDTO): StudySession;
}
```

### 3. Strategy Pattern
**Purpose:** Different calculation strategies for analytics
**Implementation:**

```typescript
interface IAnalyticsStrategy {
  calculate(sessions: StudySession[]): AnalyticsResult;
}

class DailyAverageStrategy implements IAnalyticsStrategy { }
class SubjectTimeStrategy implements IAnalyticsStrategy { }
class TimeBlockAverageStrategy implements IAnalyticsStrategy { }
```

### 4. Observer Pattern
**Purpose:** Real-time timer updates in UI
**Implementation:** Event emitters for session state changes

```typescript
class TimerService {
  private observers: Observer[] = [];

  subscribe(observer: Observer): void;
  unsubscribe(observer: Observer): void;
  notify(event: TimerEvent): void;
}
```

### 5. Command Pattern
**Purpose:** Encapsulate timer actions (start, pause, stop)
**Implementation:**

```typescript
interface ICommand {
  execute(): Promise<void>;
  undo(): Promise<void>;
}

class StartSessionCommand implements ICommand { }
class PauseSessionCommand implements ICommand { }
class EndSessionCommand implements ICommand { }
```

### 6. Dependency Injection
**Purpose:** Loose coupling between layers
**Implementation:** Using dependency injection container (e.g., TypeDI, tsyringe)

### 7. Singleton Pattern
**Purpose:** Single instance of timer service
**Implementation:** Ensures only one active timer at a time

### 8. Adapter Pattern
**Purpose:** Convert data between layers
**Implementation:** DTOs (Data Transfer Objects) for API communication

### 9. JWT Authentication Strategy
**Purpose:** Secure API endpoints and manage user sessions
**Implementation:**

```typescript
interface IAuthenticationStrategy {
  generateToken(userId: string): string;
  verifyToken(token: string): { userId: string } | null;
  hashPassword(password: string): Promise<string>;
  comparePassword(password: string, hash: string): Promise<boolean>;
}

class JWTAuthenticationStrategy implements IAuthenticationStrategy {
  generateToken(userId: string): string;
  verifyToken(token: string): { userId: string } | null;
  hashPassword(password: string): Promise<string>;
  comparePassword(password: string, hash: string): Promise<boolean>;
}
```

**Middleware:**
```typescript
async function authenticateJWT(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });

  const payload = jwtService.verifyToken(token);
  if (!payload) return res.status(403).json({ error: 'Invalid token' });

  req.userId = payload.userId;
  next();
}
```

---

## Domain Model

### Core Entities

#### User
```typescript
class User {
  id: string;
  email: string;
  password: string; // hashed
  firstName: string;
  lastName: string;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;

  // Business methods
  updateProfile(firstName: string, lastName: string): void;
  deactivate(): void;
  activate(): void;
  getFullName(): string;
}
```

#### StudySession
```typescript
class StudySession {
  id: string;
  userId: string;
  subjectId: string;
  semesterId: string;
  startTime: Date;
  endTime?: Date;
  pausedAt?: Date;
  status: SessionStatus; // ACTIVE, PAUSED, COMPLETED
  breaks: Break[];

  // Business methods
  pause(): void;
  resume(): void;
  end(): void;
  addBreak(break: Break): void;
  getTotalDuration(): number;
  getEffectiveStudyTime(): number; // excluding breaks
  isActive(): boolean;
  belongsToUser(userId: string): boolean;
}
```

#### Subject
```typescript
class Subject {
  id: string;
  userId: string;
  name: string;
  color: string;
  icon?: string;
  createdAt: Date;
  isActive: boolean;

  // Business methods
  deactivate(): void;
  activate(): void;
  updateDetails(name: string, color: string, icon?: string): void;
  belongsToUser(userId: string): boolean;
}
```

#### Break
```typescript
class Break {
  id: string;
  sessionId: string;
  startTime: Date;
  endTime?: Date;
  duration?: number; // in seconds

  // Business methods
  end(): void;
  getDuration(): number;
}
```

#### Semester
```typescript
class Semester {
  id: string;
  userId: string;
  name: string;
  startDate: Date;
  endDate: Date;
  isActive: boolean;

  // Business methods
  isWithinSemester(date: Date): boolean;
  activate(): void;
  deactivate(): void;
  belongsToUser(userId: string): boolean;
}
```

### Value Objects

#### TimeBlock
```typescript
class TimeBlock {
  hours: number;
  minutes: number;
  seconds: number;

  toSeconds(): number;
  toString(): string;
  static fromSeconds(seconds: number): TimeBlock;
}
```

---

## Database Schema

### Tables

#### users
```sql
CREATE TABLE users (
  id VARCHAR(36) PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL, -- bcrypt hashed
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_active (is_active)
);
```

#### subjects
```sql
CREATE TABLE subjects (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  color VARCHAR(7) NOT NULL,
  icon VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user (user_id),
  INDEX idx_active (is_active)
);
```

#### semesters
```sql
CREATE TABLE semesters (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user (user_id),
  INDEX idx_dates (start_date, end_date),
  INDEX idx_active (is_active)
);
```

#### study_sessions
```sql
CREATE TABLE study_sessions (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  subject_id VARCHAR(36) NOT NULL,
  semester_id VARCHAR(36) NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  paused_at DATETIME,
  status ENUM('ACTIVE', 'PAUSED', 'COMPLETED') DEFAULT 'ACTIVE',
  total_duration INT, -- in seconds
  effective_study_time INT, -- in seconds (excluding breaks)
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
  FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE,
  INDEX idx_user (user_id),
  INDEX idx_subject (subject_id),
  INDEX idx_semester (semester_id),
  INDEX idx_start_time (start_time),
  INDEX idx_status (status)
);
```

#### breaks
```sql
CREATE TABLE breaks (
  id VARCHAR(36) PRIMARY KEY,
  session_id VARCHAR(36) NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME,
  duration INT, -- in seconds
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES study_sessions(id) ON DELETE CASCADE,
  INDEX idx_session (session_id)
);
```

### Relationships
- One User → Many Subjects
- One User → Many Semesters
- One User → Many StudySessions
- One Subject → Many StudySessions
- One Semester → Many StudySessions
- One StudySession → Many Breaks

---

## API Specifications

### Base URL
```
http://localhost:3000/api/v1
```

### Authentication
All endpoints except `/auth/register` and `/auth/login` require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

### Endpoints

#### Authentication
```
POST   /auth/register         - Register a new user
POST   /auth/login            - Login and get JWT token
POST   /auth/refresh          - Refresh JWT token
POST   /auth/logout           - Logout (invalidate token)
GET    /auth/profile          - Get current user profile
PUT    /auth/profile          - Update user profile
```

#### Subjects
```
GET    /subjects              - List all subjects
POST   /subjects              - Create a new subject
GET    /subjects/:id          - Get subject by ID
PUT    /subjects/:id          - Update subject
DELETE /subjects/:id          - Delete subject
GET    /subjects/:id/stats    - Get statistics for a subject
```

#### Semesters
```
GET    /semesters             - List all semesters
POST   /semesters             - Create a new semester
GET    /semesters/:id         - Get semester by ID
PUT    /semesters/:id         - Update semester
DELETE /semesters/:id         - Delete semester
POST   /semesters/:id/activate - Set as active semester
GET    /semesters/active      - Get current active semester
```

#### Study Sessions
```
POST   /sessions/start        - Start a new study session
POST   /sessions/:id/pause    - Pause a session
POST   /sessions/:id/resume   - Resume a paused session
POST   /sessions/:id/end      - End a session
GET    /sessions              - List sessions (with filters)
GET    /sessions/:id          - Get session details
DELETE /sessions/:id          - Delete a session
GET    /sessions/active       - Get current active session
```

#### Breaks
```
POST   /sessions/:id/breaks/start  - Start a break
POST   /breaks/:id/end             - End a break
GET    /sessions/:id/breaks        - List breaks for a session
```

#### Analytics
```
GET    /analytics/daily-average           - Average daily study time
GET    /analytics/subject-breakdown       - Time spent per subject
GET    /analytics/time-blocks             - Average time blocks
GET    /analytics/semester/:id            - Semester statistics
GET    /analytics/trends                  - Study trends over time
```

#### Export (PDF)
```
GET    /export/sessions/pdf               - Export sessions to PDF
GET    /export/analytics/pdf              - Export analytics to PDF
GET    /export/subject/:id/pdf            - Export subject report to PDF
GET    /export/semester/:id/pdf           - Export semester report to PDF
```

### Request/Response Examples

#### POST /auth/register
**Request:**
```json
{
  "email": "student@example.com",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Response:**
```json
{
  "id": "uuid-111",
  "email": "student@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "createdAt": "2025-10-15T10:00:00Z"
}
```

#### POST /auth/login
**Request:**
```json
{
  "email": "student@example.com",
  "password": "SecurePass123!"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-111",
    "email": "student@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }
}
```

#### POST /sessions/start
**Request:**
```json
{
  "subjectId": "uuid-123",
  "semesterId": "uuid-456"
}
```

**Response:**
```json
{
  "id": "uuid-789",
  "subjectId": "uuid-123",
  "semesterId": "uuid-456",
  "startTime": "2025-10-15T10:30:00Z",
  "status": "ACTIVE"
}
```

#### GET /analytics/daily-average
**Query Params:** `?startDate=2025-09-01&endDate=2025-10-15`

**Response:**
```json
{
  "averageMinutesPerDay": 180,
  "totalDays": 45,
  "totalStudyTime": 8100,
  "consistency": 0.87
}
```

---

## Frontend Architecture

### React Component Hierarchy

```
App
├── Auth Pages (Public Routes)
│   ├── LoginPage
│   │   ├── LoginForm
│   │   └── SocialLogin (future)
│   ├── RegisterPage
│   │   └── RegisterForm
│   └── ForgotPasswordPage (future)
├── Protected Routes (Requires Authentication)
│   ├── Layout
│   │   ├── Header
│   │   │   ├── UserMenu
│   │   │   └── Notifications
│   │   ├── Sidebar
│   │   │   └── Navigation
│   │   └── MainContent
│   ├── Pages
│   │   ├── Dashboard
│   │   │   ├── ActiveTimer
│   │   │   │   ├── TimerDisplay
│   │   │   │   ├── TimerControls
│   │   │   │   └── BreakButton
│   │   │   ├── QuickStats
│   │   │   └── RecentSessions
│   │   ├── SubjectsPage
│   │   │   ├── SubjectList
│   │   │   ├── SubjectCard
│   │   │   └── SubjectForm
│   │   ├── SessionsPage
│   │   │   ├── SessionFilters
│   │   │   ├── SessionList
│   │   │   └── SessionDetails
│   │   ├── AnalyticsPage
│   │   │   ├── TimeSpentChart
│   │   │   ├── DailyAverageChart
│   │   │   ├── SubjectBreakdown
│   │   │   ├── StatCards
│   │   │   └── ExportButton (PDF)
│   │   └── ProfilePage
│   │       ├── ProfileForm
│   │       └── AccountSettings
└── Shared Components
    ├── Button
    ├── Card
    ├── Modal
    ├── DatePicker
    ├── ProtectedRoute
    └── Charts (using Chart.js or Recharts)
```

### State Management

**Approach:** Context API + Custom Hooks (or Redux Toolkit for scalability)

**Contexts:**
1. `AuthContext` - User authentication state and token management
2. `TimerContext` - Active session state
3. `SubjectsContext` - Subject list and CRUD operations
4. `SemesterContext` - Current semester
5. `AnalyticsContext` - Cached analytics data

**Custom Hooks:**
- `useAuth()` - Authentication (login, logout, register)
- `useTimer()` - Timer logic and controls
- `useStudySession()` - Session CRUD operations
- `useSubjects()` - Subject management
- `useAnalytics()` - Fetch and cache analytics
- `useBreak()` - Break tracking
- `useExport()` - PDF export functionality

---

## Project Structure

```
time-tracker/
├── backend/
│   ├── src/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── User.ts
│   │   │   │   ├── StudySession.ts
│   │   │   │   ├── Subject.ts
│   │   │   │   ├── Break.ts
│   │   │   │   └── Semester.ts
│   │   │   ├── value-objects/
│   │   │   │   └── TimeBlock.ts
│   │   │   ├── repositories/
│   │   │   │   ├── IUserRepository.ts
│   │   │   │   ├── IStudySessionRepository.ts
│   │   │   │   ├── ISubjectRepository.ts
│   │   │   │   ├── IBreakRepository.ts
│   │   │   │   └── ISemesterRepository.ts
│   │   │   └── services/
│   │   │       └── DomainServices.ts
│   │   ├── application/
│   │   │   ├── use-cases/
│   │   │   │   ├── auth/
│   │   │   │   │   ├── RegisterUser.ts
│   │   │   │   │   ├── LoginUser.ts
│   │   │   │   │   ├── RefreshToken.ts
│   │   │   │   │   ├── LogoutUser.ts
│   │   │   │   │   ├── GetUserProfile.ts
│   │   │   │   │   └── UpdateUserProfile.ts
│   │   │   │   ├── session/
│   │   │   │   │   ├── StartStudySession.ts
│   │   │   │   │   ├── PauseStudySession.ts
│   │   │   │   │   ├── ResumeStudySession.ts
│   │   │   │   │   └── EndStudySession.ts
│   │   │   │   ├── subject/
│   │   │   │   │   ├── CreateSubject.ts
│   │   │   │   │   ├── UpdateSubject.ts
│   │   │   │   │   └── DeleteSubject.ts
│   │   │   │   ├── break/
│   │   │   │   │   ├── StartBreak.ts
│   │   │   │   │   └── EndBreak.ts
│   │   │   │   ├── analytics/
│   │   │   │   │   ├── GetDailyAverage.ts
│   │   │   │   │   ├── GetSubjectStats.ts
│   │   │   │   │   └── GetTimeBlockAverage.ts
│   │   │   │   └── export/
│   │   │   │       ├── ExportSessionsToPDF.ts
│   │   │   │       ├── ExportAnalyticsToPDF.ts
│   │   │   │       ├── ExportSubjectReportToPDF.ts
│   │   │   │       └── ExportSemesterReportToPDF.ts
│   │   │   ├── dto/
│   │   │   │   ├── UserDTO.ts
│   │   │   │   ├── AuthDTO.ts
│   │   │   │   ├── StudySessionDTO.ts
│   │   │   │   ├── SubjectDTO.ts
│   │   │   │   └── AnalyticsDTO.ts
│   │   │   └── services/
│   │   │       ├── AuthService.ts
│   │   │       ├── TimerService.ts
│   │   │       ├── AnalyticsService.ts
│   │   │       └── PDFExportService.ts
│   │   ├── infrastructure/
│   │   │   ├── database/
│   │   │   │   ├── migrations/
│   │   │   │   ├── MySQLConnection.ts
│   │   │   │   └── repositories/
│   │   │   │       ├── UserRepository.ts
│   │   │   │       ├── StudySessionRepository.ts
│   │   │   │       ├── SubjectRepository.ts
│   │   │   │       ├── BreakRepository.ts
│   │   │   │       └── SemesterRepository.ts
│   │   │   ├── adapters/
│   │   │   │   ├── ChartDataAdapter.ts
│   │   │   │   └── PDFAdapter.ts
│   │   │   ├── security/
│   │   │   │   ├── JWTService.ts
│   │   │   │   └── PasswordHashingService.ts
│   │   │   └── config/
│   │   │       ├── database.config.ts
│   │   │       ├── jwt.config.ts
│   │   │       └── app.config.ts
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   ├── AuthController.ts
│   │   │   │   ├── SessionController.ts
│   │   │   │   ├── SubjectController.ts
│   │   │   │   ├── BreakController.ts
│   │   │   │   ├── AnalyticsController.ts
│   │   │   │   └── ExportController.ts
│   │   │   ├── middlewares/
│   │   │   │   ├── authenticate.ts
│   │   │   │   ├── errorHandler.ts
│   │   │   │   ├── validator.ts
│   │   │   │   └── logger.ts
│   │   │   └── routes/
│   │   │       ├── auth.routes.ts
│   │   │       ├── session.routes.ts
│   │   │       ├── subject.routes.ts
│   │   │       ├── break.routes.ts
│   │   │       ├── semester.routes.ts
│   │   │       ├── analytics.routes.ts
│   │   │       └── export.routes.ts
│   │   ├── shared/
│   │   │   ├── errors/
│   │   │   │   └── AppError.ts
│   │   │   ├── utils/
│   │   │   │   ├── dateUtils.ts
│   │   │   │   └── timeUtils.ts
│   │   │   └── types/
│   │   │       └── common.types.ts
│   │   └── index.ts
│   ├── tests/
│   │   ├── unit/
│   │   ├── integration/
│   │   └── e2e/
│   ├── package.json
│   ├── tsconfig.json
│   └── .env
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── auth/
│   │   │   │   ├── LoginForm.tsx
│   │   │   │   ├── RegisterForm.tsx
│   │   │   │   ├── ProfileForm.tsx
│   │   │   │   └── ProtectedRoute.tsx
│   │   │   ├── timer/
│   │   │   │   ├── ActiveTimer.tsx
│   │   │   │   ├── TimerDisplay.tsx
│   │   │   │   ├── TimerControls.tsx
│   │   │   │   └── BreakButton.tsx
│   │   │   ├── subjects/
│   │   │   │   ├── SubjectList.tsx
│   │   │   │   ├── SubjectCard.tsx
│   │   │   │   └── SubjectForm.tsx
│   │   │   ├── sessions/
│   │   │   │   ├── SessionList.tsx
│   │   │   │   ├── SessionCard.tsx
│   │   │   │   └── SessionFilters.tsx
│   │   │   ├── analytics/
│   │   │   │   ├── TimeSpentChart.tsx
│   │   │   │   ├── DailyAverageChart.tsx
│   │   │   │   ├── SubjectBreakdown.tsx
│   │   │   │   ├── StatCards.tsx
│   │   │   │   └── ExportButton.tsx
│   │   │   ├── layout/
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   ├── UserMenu.tsx
│   │   │   │   └── Layout.tsx
│   │   │   └── shared/
│   │   │       ├── Button.tsx
│   │   │       ├── Card.tsx
│   │   │       ├── Modal.tsx
│   │   │       └── DatePicker.tsx
│   │   ├── pages/
│   │   │   ├── LoginPage.tsx
│   │   │   ├── RegisterPage.tsx
│   │   │   ├── ProfilePage.tsx
│   │   │   ├── Dashboard.tsx
│   │   │   ├── SubjectsPage.tsx
│   │   │   ├── SessionsPage.tsx
│   │   │   └── AnalyticsPage.tsx
│   │   ├── contexts/
│   │   │   ├── AuthContext.tsx
│   │   │   ├── TimerContext.tsx
│   │   │   ├── SubjectsContext.tsx
│   │   │   ├── SemesterContext.tsx
│   │   │   └── AnalyticsContext.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useTimer.ts
│   │   │   ├── useStudySession.ts
│   │   │   ├── useSubjects.ts
│   │   │   ├── useAnalytics.ts
│   │   │   ├── useBreak.ts
│   │   │   └── useExport.ts
│   │   ├── services/
│   │   │   ├── api.ts
│   │   │   ├── authService.ts
│   │   │   ├── sessionService.ts
│   │   │   ├── subjectService.ts
│   │   │   ├── analyticsService.ts
│   │   │   └── exportService.ts
│   │   ├── utils/
│   │   │   ├── formatTime.ts
│   │   │   ├── dateHelpers.ts
│   │   │   └── chartHelpers.ts
│   │   ├── types/
│   │   │   ├── auth.types.ts
│   │   │   ├── user.types.ts
│   │   │   ├── session.types.ts
│   │   │   ├── subject.types.ts
│   │   │   └── analytics.types.ts
│   │   ├── App.tsx
│   │   ├── index.tsx
│   │   └── styles/
│   │       └── globals.css
│   ├── package.json
│   └── tsconfig.json
└── README.md
```

---

## Technology Stack

### Backend
- **Runtime:** Node.js (v18+)
- **Framework:** Express.js
- **Language:** TypeScript
- **Database:** MySQL 8.0+
- **ORM/Query Builder:** TypeORM or Prisma
- **Authentication:**
  - jsonwebtoken (JWT)
  - bcrypt (password hashing)
  - express-rate-limit (rate limiting)
- **PDF Generation:** PDFKit or Puppeteer
- **Validation:** Zod or Joi
- **Dependency Injection:** tsyringe or TypeDI
- **Testing:** Jest + Supertest
- **API Documentation:** Swagger/OpenAPI

### Frontend
- **Framework:** React 18+
- **Language:** TypeScript
- **Build Tool:** Vite
- **Routing:** React Router v6
- **State Management:** Context API + useReducer (or Redux Toolkit)
- **UI Library:** Material-UI or Tailwind CSS + Headless UI
- **Charts:** Recharts or Chart.js (react-chartjs-2)
- **HTTP Client:** Axios
- **Date Handling:** date-fns or Day.js
- **Form Handling:** React Hook Form
- **Testing:** Vitest + React Testing Library

### DevOps & Tools
- **Version Control:** Git
- **Package Manager:** npm or pnpm
- **Linting:** ESLint
- **Formatting:** Prettier
- **Pre-commit Hooks:** Husky + lint-staged
- **Environment Variables:** dotenv
- **API Testing:** Postman or Insomnia

### Database Tools
- **Migration:** TypeORM migrations or Prisma migrate
- **Seeding:** Custom seed scripts
- **Backup:** mysqldump

---

## Implementation Phases

### Phase 1: Foundation & Authentication
1. Project setup (backend + frontend)
2. Database schema creation with users table
3. Domain entities implementation (User, StudySession, Subject, etc.)
4. Repository interfaces
5. JWT authentication system
6. User registration and login
7. Protected routes and middleware

### Phase 2: Core Features
1. Timer functionality (start/stop/pause)
2. Subject CRUD operations (per user)
3. Session tracking (with user association)
4. Break tracking
5. Semester management (per user)

### Phase 3: Data & Analytics
1. Session history (user-specific)
2. Basic analytics (daily average, subject time)
3. Advanced analytics (time blocks, trends)
4. Analytics dashboard UI

### Phase 4: Visualization & Export
1. Chart implementation (Recharts)
2. Dashboard UI with real-time updates
3. PDF export functionality
4. Export reports for sessions, subjects, and semesters

### Phase 5: Polish & Optimization
1. Responsive design
2. Performance optimization
3. Error handling and validation
4. User profile management

### Phase 6: Testing & Deployment
1. Unit tests for all layers
2. Integration tests for API endpoints
3. E2E tests for critical user flows
4. LocalHost deployment setup

---

## Next Steps

1. **Review and approve this architecture**
2. **Set up project structure** - Create backend and frontend directories
3. **Initialize backend project**
   - npm init + TypeScript setup
   - Install dependencies (Express, TypeORM/Prisma, JWT, bcrypt, etc.)
   - Configure database connection
4. **Initialize frontend project**
   - Create React app with Vite
   - Install dependencies (React Router, Axios, Recharts, etc.)
   - Configure Tailwind CSS or Material-UI
5. **Create database and run migrations**
   - Create MySQL database
   - Run migration scripts for all tables
   - Seed initial data (optional)
6. **Begin implementation with Phase 1**
   - Implement User entity and authentication
   - Build login/register pages
   - Set up JWT middleware

---

## Feature Roadmap (Future Enhancements)

- Dark mode support
- Email notifications for break reminders
- Export to CSV format
- Social authentication (Google, GitHub)
- Mobile responsive PWA
- Pomodoro timer integration
- Study goals and achievements
- Team/Study group features

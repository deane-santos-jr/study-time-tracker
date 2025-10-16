# TimeTracker Backend API

Backend API for the TimeTracker application built with Clean Architecture principles.

## Tech Stack

- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Language:** TypeScript
- **Database:** MySQL 8.0+
- **ORM:** TypeORM
- **Authentication:** JWT + bcrypt

## Project Structure

```
backend/
├── src/
│   ├── domain/              # Business logic & entities
│   ├── application/         # Use cases
│   ├── infrastructure/      # External services & database
│   ├── presentation/        # Controllers & routes
│   └── shared/             # Shared utilities
├── tests/                  # Test files
├── package.json
├── tsconfig.json
└── .env
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

Required environment variables:
- `PORT` - Server port (default: 3000)
- `DB_HOST` - MySQL host (default: localhost)
- `DB_PORT` - MySQL port (default: 3306)
- `DB_USERNAME` - MySQL username (default: root)
- `DB_PASSWORD` - MySQL password
- `DB_DATABASE` - Database name (default: timetracker)
- `JWT_SECRET` - Secret for JWT token generation
- `JWT_REFRESH_SECRET` - Secret for refresh token
- `CORS_ORIGIN` - Frontend URL (default: http://localhost:5173)

### 3. Create MySQL Database

**Option 1: Using MySQL Command Line**
```bash
mysql -u root -p
```

Then run:
```sql
CREATE DATABASE timetracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

**Option 2: Using XAMPP phpMyAdmin**
1. Open http://localhost/phpmyadmin
2. Click "New" in the left sidebar
3. Database name: `timetracker`
4. Collation: `utf8mb4_unicode_ci`
5. Click "Create"

### 4. Run Database Migrations

```bash
npm run migration:run
```

This will create all the required tables:
- users
- subjects
- semesters
- study_sessions
- breaks

### 5. Start the Development Server

```bash
npm run dev
```

The server will start on `http://localhost:3000`

## Available Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build TypeScript to JavaScript
- `npm start` - Start production server
- `npm test` - Run tests
- `npm run migration:generate` - Generate a new migration
- `npm run migration:run` - Run pending migrations
- `npm run migration:revert` - Revert last migration

## API Endpoints

### Health Check
```
GET /health
```

### Authentication

#### Register
```
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login
```
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

Response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe"
    }
  }
}
```

#### Get Profile (Protected)
```
GET /api/v1/auth/profile
Authorization: Bearer <token>
```

#### Refresh Token
```
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout (Protected)
```
POST /api/v1/auth/logout
Authorization: Bearer <token>
```

## Testing the API

### Using cURL

**Register:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!",
    "firstName": "Test",
    "lastName": "User"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234!"
  }'
```

**Get Profile:**
```bash
curl -X GET http://localhost:3000/api/v1/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Using Postman or Insomnia

1. Import the API endpoints
2. Set base URL to `http://localhost:3000`
3. For protected routes, add `Authorization: Bearer <token>` header

## Password Requirements

- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (!@#$%^&*(),.?":{}|<>)

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "message": "Error message here"
}
```

HTTP Status Codes:
- `200` - Success
- `201` - Created
- `400` - Validation Error
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict (e.g., email already exists)
- `500` - Internal Server Error

## Clean Architecture Layers

### Domain Layer
Pure business logic with no external dependencies. Contains:
- Entities (User, Subject, StudySession, etc.)
- Repository interfaces
- Business rules

### Application Layer
Use cases that orchestrate domain entities. Contains:
- RegisterUser
- LoginUser
- RefreshToken
- GetUserProfile

### Infrastructure Layer
External concerns and implementations. Contains:
- Database repositories (TypeORM)
- JWT service
- Password hashing service
- Configuration files

### Presentation Layer
HTTP interface. Contains:
- Controllers
- Routes
- Middlewares (authentication, validation, error handling)

## Troubleshooting

### Database Connection Issues

1. **Error: Access denied for user**
   - Check DB_USERNAME and DB_PASSWORD in .env
   - Ensure MySQL user has proper permissions

2. **Error: Unknown database 'timetracker'**
   - Create the database first (see Setup step 3)

3. **Error: ECONNREFUSED**
   - Make sure MySQL is running
   - Check DB_HOST and DB_PORT in .env

### Migration Issues

1. **Error: No migrations to run**
   - Migrations are already applied
   - Check the `migrations` table in your database

2. **Error: Table already exists**
   - Drop the database and recreate it
   - Or manually revert migrations

### TypeScript Issues

1. **Error: Cannot find module**
   - Run `npm install` to install dependencies
   - Check import paths

## Development

### Adding New Endpoints

1. Create use case in `application/use-cases/`
2. Add controller method in `presentation/controllers/`
3. Add route in `presentation/routes/`
4. Add validation schema if needed

### Running in Production

1. Build the project: `npm run build`
2. Set `NODE_ENV=production` in .env
3. Start server: `npm start`

## License

ISC

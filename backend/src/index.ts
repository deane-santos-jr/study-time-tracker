import 'reflect-metadata';
import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { AppDataSource } from './infrastructure/config/database.config';
import { appConfig } from './infrastructure/config/app.config';
import { errorHandler } from './presentation/middlewares/errorHandler';
import { logger } from './presentation/middlewares/logger';
import authRoutes from './presentation/routes/auth.routes';
import subjectRoutes from './presentation/routes/subject.routes';
import sessionRoutes from './presentation/routes/session.routes';
import analyticsRoutes from './presentation/routes/analytics.routes';
import semesterRoutes from './presentation/routes/semester.routes';

// Load environment variables
dotenv.config();

class Server {
  private app: Application;
  private port: number;

  constructor() {
    this.app = express();
    this.port = appConfig.port;
    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  private initializeMiddlewares(): void {
    // CORS configuration
    this.app.use(
      cors({
        origin: appConfig.corsOrigin,
        credentials: true,
      })
    );

    // Body parsing
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));

    // Request logging
    this.app.use(logger);
  }

  private initializeRoutes(): void {
    // Health check route
    this.app.get('/health', (_req, res) => {
      res.status(200).json({
        success: true,
        message: 'Server is running',
        timestamp: new Date().toISOString(),
      });
    });

    // API routes
    this.app.use('/api/v1/auth', authRoutes);
    this.app.use('/api/v1/semesters', semesterRoutes);
    this.app.use('/api/v1/subjects', subjectRoutes);
    this.app.use('/api/v1/sessions', sessionRoutes);
    this.app.use('/api/v1/analytics', analyticsRoutes);

    // 404 handler
    this.app.use('*', (req, res) => {
      res.status(404).json({
        success: false,
        message: `Route ${req.originalUrl} not found`,
      });
    });
  }

  private initializeErrorHandling(): void {
    this.app.use(errorHandler);
  }

  private async initializeDatabase(): Promise<void> {
    try {
      await AppDataSource.initialize();
      console.log('✅ Database connected successfully');
    } catch (error) {
      console.error('❌ Database connection failed:', error);
      process.exit(1);
    }
  }

  public async start(): Promise<void> {
    try {
      // Initialize database connection
      await this.initializeDatabase();

      // Start server
      this.app.listen(this.port, () => {
        console.log(`🚀 Server is running on port ${this.port}`);
        console.log(`📍 Environment: ${appConfig.nodeEnv}`);
        console.log(`🔗 Health check: http://localhost:${this.port}/health`);
        console.log(`🔒 Auth API: http://localhost:${this.port}/api/v1/auth`);
        console.log(`📅 Semesters API: http://localhost:${this.port}/api/v1/semesters`);
        console.log(`📚 Subjects API: http://localhost:${this.port}/api/v1/subjects`);
        console.log(`⏱️  Sessions API: http://localhost:${this.port}/api/v1/sessions`);
        console.log(`📊 Analytics API: http://localhost:${this.port}/api/v1/analytics`);
      });
    } catch (error) {
      console.error('Failed to start server:', error);
      process.exit(1);
    }
  }
}

// Start the server
const server = new Server();
server.start();

// Handle unhandled promise rejections
process.on('unhandledRejection', (err: Error) => {
  console.error('Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err: Error) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

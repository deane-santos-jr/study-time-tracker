import 'reflect-metadata';
import express, { Application } from 'express';
import { AppDataSource } from '../../infrastructure/config/database.config';
import authRoutes from '../../presentation/routes/auth.routes';
import semesterRoutes from '../../presentation/routes/semester.routes';
import subjectRoutes from '../../presentation/routes/subject.routes';
import sessionRoutes from '../../presentation/routes/session.routes';
import { errorHandler } from '../../presentation/middlewares/errorHandler';

let app: Application | null = null;

export async function getTestApp(): Promise<Application> {
  if (app) return app;
  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }
  const instance = express();
  instance.use(express.json());
  instance.use('/api/v1/auth', authRoutes);
  instance.use('/api/v1/semesters', semesterRoutes);
  instance.use('/api/v1/subjects', subjectRoutes);
  instance.use('/api/v1/sessions', sessionRoutes);
  instance.use(errorHandler);
  app = instance;
  return app;
}

export async function closeTestApp(): Promise<void> {
  if (AppDataSource.isInitialized) {
    await AppDataSource.destroy();
  }
  app = null;
}

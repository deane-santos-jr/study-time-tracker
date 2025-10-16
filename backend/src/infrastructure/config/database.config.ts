import { DataSource } from 'typeorm';
import dotenv from 'dotenv';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  username: process.env.DB_USERNAME || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'timetracker',
  synchronize: false, // Never use true in production
  logging: process.env.NODE_ENV === 'development',
  entities: [
    __dirname + '/../database/entities/**/*.ts',
    __dirname + '/../database/entities/**/*.js',
  ],
  migrations: [
    __dirname + '/../database/migrations/**/*.ts',
    __dirname + '/../database/migrations/**/*.js',
  ],
  subscribers: [],
});

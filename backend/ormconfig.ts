import { DataSource } from 'typeorm';
import { config } from 'dotenv';

config();

export default new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '3306'),
  username: process.env.DB_USERNAME || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'timetracker',
  synchronize: false,
  logging: false,
  entities: ['src/infrastructure/database/entities/**/*.ts'],
  migrations: ['src/infrastructure/database/migrations/**/*.ts'],
  subscribers: [],
});

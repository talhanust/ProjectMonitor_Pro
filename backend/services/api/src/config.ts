import dotenv from 'dotenv';
dotenv.config();

export const config = {
  PORT: parseInt(process.env['PORT'] || '8080', 10),
  NODE_ENV: process.env['NODE_ENV'] || 'development',
  DATABASE_URL:
    process.env['DATABASE_URL'] || 'postgresql://user:password@localhost:5432/engineering_app',
  JWT_SECRET: process.env['JWT_SECRET'] || 'your-secret-key',
};

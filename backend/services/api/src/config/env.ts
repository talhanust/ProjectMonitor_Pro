import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('8080').transform(Number),
  DATABASE_URL: z.string().default('postgresql://localhost:5432/engineering_app'),
  JWT_SECRET: z.string().default('your-secret-key-change-in-production'),
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
});

export const config = envSchema.parse(process.env);

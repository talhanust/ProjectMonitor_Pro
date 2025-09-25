import { z } from 'zod';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

// Possible .env locations (check both root and prisma folder)
const envPaths = [
  path.resolve(__dirname, '../../.env'),
  path.resolve(__dirname, '../../prisma/.env'),
];

// Load the first existing .env file
for (const envPath of envPaths) {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath });
    break;
  }
}

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('8080').transform(Number),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().default('your-secret-key-change-in-production'),
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
});

export const config = envSchema.parse(process.env);

import { z } from 'zod'
import dotenv from 'dotenv'

dotenv.config()

const configSchema = z.object({
  // Environment
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  
  // Server
  PORT: z.string().default('8080').transform(Number),
  HOST: z.string().default('0.0.0.0'),
  
  // Database
  DATABASE_URL: z.string().default('postgresql://localhost:5432/engineering_app'),
  
  // JWT
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRY: z.string().default('7d'),
  JWT_REFRESH_EXPIRY: z.string().default('30d'),
  
  // CORS
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
  
  // Rate limiting
  RATE_LIMIT_MAX: z.string().default('100').transform(Number),
  RATE_LIMIT_WINDOW: z.string().default('15 minutes'),
  
  // Logging
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  
  // API Keys (optional)
  API_KEY: z.string().optional(),
  
  // Email (optional)
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.string().optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
})

export type Config = z.infer<typeof configSchema>

const parseResult = configSchema.safeParse(process.env)

if (!parseResult.success) {
  console.error('❌ Invalid configuration:', parseResult.error.format())
  process.exit(1)
}

export const config = parseResult.data

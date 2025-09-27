#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     Backend Core Services Setup Script        ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}Error: Not in project root directory!${NC}"
    exit 1
fi

# Create API Gateway directory structure
echo -e "${GREEN}Creating API Gateway directory structure...${NC}"
mkdir -p backend/services/api-gateway/src/{middleware,routes,config,controllers,services,utils,types}
mkdir -p backend/services/api-gateway/tests

# PART 1: Package.json for API Gateway
echo -e "${GREEN}Creating package.json for API Gateway...${NC}"
cat > backend/services/api-gateway/package.json << 'PACKAGE'
{
  "name": "@backend/api-gateway",
  "version": "1.0.0",
  "private": true,
  "description": "API Gateway service with Express/Fastify",
  "main": "dist/server.js",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext ts --report-unused-disable-directives --max-warnings 0",
    "typecheck": "tsc --noEmit",
    "clean": "rimraf dist node_modules .turbo"
  },
  "dependencies": {
    "@fastify/compress": "^6.5.0",
    "@fastify/cors": "^8.5.0",
    "@fastify/helmet": "^11.1.1",
    "@fastify/jwt": "^7.2.4",
    "@fastify/rate-limit": "^9.1.0",
    "@fastify/swagger": "^8.14.0",
    "@fastify/swagger-ui": "^2.1.0",
    "fastify": "^4.25.2",
    "fastify-plugin": "^4.5.1",
    "@sinclair/typebox": "^0.32.5",
    "bcryptjs": "^2.4.3",
    "dotenv": "^16.3.1",
    "pino": "^8.17.2",
    "pino-pretty": "^10.3.1",
    "zod": "^3.22.4",
    "jsonwebtoken": "^9.0.2",
    "@prisma/client": "^5.8.0"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "@types/bcryptjs": "^2.4.6",
    "@types/jsonwebtoken": "^9.0.5",
    "@vitest/ui": "^1.2.0",
    "prisma": "^5.8.0",
    "tsx": "^4.7.0",
    "vitest": "^1.2.0",
    "typescript": "^5.3.3",
    "eslint": "^8.56.0",
    "@typescript-eslint/eslint-plugin": "^6.19.0",
    "@typescript-eslint/parser": "^6.19.0",
    "rimraf": "^5.0.5"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
PACKAGE

# PART 2: TypeScript Configuration
echo -e "${GREEN}Creating TypeScript configuration...${NC}"
cat > backend/services/api-gateway/tsconfig.json << 'TSCONFIG'
{
  "extends": "../../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "./src",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@config/*": ["./src/config/*"],
      "@middleware/*": ["./src/middleware/*"],
      "@controllers/*": ["./src/controllers/*"],
      "@services/*": ["./src/services/*"],
      "@routes/*": ["./src/routes/*"],
      "@utils/*": ["./src/utils/*"],
      "@types/*": ["./src/types/*"]
    },
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "allowSyntheticDefaultImports": true,
    "experimentalDecorators": true,
    "emitDecoratorMetadata": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "coverage", "tests"]
}
TSCONFIG

# PART 3: Main Application (app.ts)
echo -e "${GREEN}Creating main application file...${NC}"
cat > backend/services/api-gateway/src/app.ts << 'APP'
import Fastify, { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import compress from '@fastify/compress'
import rateLimit from '@fastify/rate-limit'
import jwt from '@fastify/jwt'
import swagger from '@fastify/swagger'
import swaggerUI from '@fastify/swagger-ui'
import { config } from './config'
import { errorHandler } from './middleware/errorHandler'
import { logger } from './utils/logger'
import { healthRoutes } from './routes/health'
import { authRoutes } from './routes/auth'
import { apiRoutes } from './routes/api'

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger,
    trustProxy: true,
    requestIdHeader: 'x-request-id',
    requestIdLogLabel: 'reqId',
    disableRequestLogging: false,
    bodyLimit: 1048576, // 1MB
  })

  // Register plugins
  await app.register(helmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
      },
    },
  })

  await app.register(cors, {
    origin: config.CORS_ORIGIN,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  })

  await app.register(compress, {
    global: true,
    threshold: 1024,
    encodings: ['gzip', 'deflate'],
  })

  await app.register(rateLimit, {
    max: config.RATE_LIMIT_MAX,
    timeWindow: config.RATE_LIMIT_WINDOW,
    cache: 10000,
    allowList: ['127.0.0.1'],
    skipOnError: true,
  })

  await app.register(jwt, {
    secret: config.JWT_SECRET,
    sign: {
      expiresIn: config.JWT_EXPIRY,
    },
  })

  // Swagger documentation
  if (config.NODE_ENV !== 'production') {
    await app.register(swagger, {
      swagger: {
        info: {
          title: 'API Gateway',
          description: 'Engineering Platform API Gateway',
          version: '1.0.0',
        },
        externalDocs: {
          url: 'https://github.com/your-repo',
          description: 'Find more info here',
        },
        host: `localhost:${config.PORT}`,
        schemes: ['http', 'https'],
        consumes: ['application/json'],
        produces: ['application/json'],
        tags: [
          { name: 'health', description: 'Health check endpoints' },
          { name: 'auth', description: 'Authentication endpoints' },
          { name: 'api', description: 'API endpoints' },
        ],
      },
    })

    await app.register(swaggerUI, {
      routePrefix: '/documentation',
      uiConfig: {
        docExpansion: 'list',
        deepLinking: false,
      },
      staticCSP: true,
      transformStaticCSP: (header) => header,
    })
  }

  // Custom error handler
  app.setErrorHandler(errorHandler)

  // Hooks
  app.addHook('onRequest', async (request: FastifyRequest, reply: FastifyReply) => {
    request.log.info({ url: request.url, method: request.method }, 'incoming request')
  })

  app.addHook('onResponse', async (request: FastifyRequest, reply: FastifyReply) => {
    request.log.info(
      { url: request.url, statusCode: reply.statusCode, responseTime: reply.getResponseTime() },
      'request completed'
    )
  })

  // Register routes
  await app.register(healthRoutes, { prefix: '/health' })
  await app.register(authRoutes, { prefix: '/auth' })
  await app.register(apiRoutes, { prefix: '/api/v1' })

  // 404 handler
  app.setNotFoundHandler((request: FastifyRequest, reply: FastifyReply) => {
    reply.status(404).send({
      statusCode: 404,
      error: 'Not Found',
      message: `Route ${request.method}:${request.url} not found`,
    })
  })

  return app
}
APP

# PART 4: Server initialization (server.ts)
echo -e "${GREEN}Creating server initialization file...${NC}"
cat > backend/services/api-gateway/src/server.ts << 'SERVER'
import { buildApp } from './app'
import { config } from './config'
import { logger } from './utils/logger'
import { connectDatabase } from './utils/database'

async function start() {
  try {
    // Connect to database
    await connectDatabase()

    // Build and start the app
    const app = await buildApp()

    await app.listen({
      port: config.PORT,
      host: '0.0.0.0',
    })

    logger.info(`🚀 Server running at http://localhost:${config.PORT}`)
    
    if (config.NODE_ENV !== 'production') {
      logger.info(`📚 API Documentation at http://localhost:${config.PORT}/documentation`)
    }

    // Graceful shutdown
    const signals = ['SIGINT', 'SIGTERM']
    signals.forEach((signal) => {
      process.on(signal, async () => {
        logger.info(`Received ${signal}, shutting down gracefully...`)
        await app.close()
        process.exit(0)
      })
    })
  } catch (err) {
    logger.error(err, 'Failed to start server')
    process.exit(1)
  }
}

start()
SERVER

# PART 5: Configuration management
echo -e "${GREEN}Creating configuration management...${NC}"
cat > backend/services/api-gateway/src/config/index.ts << 'CONFIG'
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
CONFIG

# PART 6: Authentication middleware
echo -e "${GREEN}Creating authentication middleware...${NC}"
cat > backend/services/api-gateway/src/middleware/auth.ts << 'AUTH'
import { FastifyRequest, FastifyReply } from 'fastify'
import { config } from '../config'

export interface User {
  id: string
  email: string
  role: string
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: User
  }
}

export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify()
    // The JWT token is valid and the user info is available in request.user
  } catch (err) {
    reply.status(401).send({ error: 'Unauthorized', message: 'Invalid or missing token' })
  }
}

export async function authorizeRoles(...roles: string[]) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    await authenticate(request, reply)
    
    if (!request.user) {
      return reply.status(401).send({ error: 'Unauthorized' })
    }

    const userRole = (request.user as any).role
    
    if (!roles.includes(userRole)) {
      return reply.status(403).send({ 
        error: 'Forbidden', 
        message: 'Insufficient permissions' 
      })
    }
  }
}

export async function optionalAuth(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify()
  } catch (err) {
    // Token is invalid or missing, but we continue anyway
    request.user = undefined
  }
}
AUTH

# PART 7: Error handler middleware
echo -e "${GREEN}Creating error handler middleware...${NC}"
cat > backend/services/api-gateway/src/middleware/errorHandler.ts << 'ERROR'
import { FastifyError, FastifyRequest, FastifyReply } from 'fastify'
import { ZodError } from 'zod'
import { config } from '../config'

export interface ApiError extends Error {
  statusCode?: number
  validation?: any
}

export async function errorHandler(
  error: FastifyError | ApiError | ZodError,
  request: FastifyRequest,
  reply: FastifyReply
) {
  // Log the error
  request.log.error(error)

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    return reply.status(400).send({
      statusCode: 400,
      error: 'Validation Error',
      message: 'Invalid request data',
      validation: error.errors,
    })
  }

  // Handle JWT errors
  if (error.message === 'No Authorization was found in request.headers') {
    return reply.status(401).send({
      statusCode: 401,
      error: 'Unauthorized',
      message: 'Missing authentication token',
    })
  }

  // Handle rate limit errors
  if ((error as any).statusCode === 429) {
    return reply.status(429).send({
      statusCode: 429,
      error: 'Too Many Requests',
      message: 'Rate limit exceeded. Please try again later.',
    })
  }

  // Handle custom API errors
  const statusCode = (error as ApiError).statusCode || 500
  const message = error.message || 'Internal Server Error'

  // Don't expose internal errors in production
  if (config.NODE_ENV === 'production' && statusCode === 500) {
    return reply.status(500).send({
      statusCode: 500,
      error: 'Internal Server Error',
      message: 'An unexpected error occurred',
    })
  }

  return reply.status(statusCode).send({
    statusCode,
    error: error.name || 'Error',
    message,
    ...(config.NODE_ENV !== 'production' && { stack: error.stack }),
  })
}

export class ValidationError extends Error {
  statusCode = 400
  
  constructor(message: string, public validation?: any) {
    super(message)
    this.name = 'ValidationError'
  }
}

export class UnauthorizedError extends Error {
  statusCode = 401
  
  constructor(message = 'Unauthorized') {
    super(message)
    this.name = 'UnauthorizedError'
  }
}

export class ForbiddenError extends Error {
  statusCode = 403
  
  constructor(message = 'Forbidden') {
    super(message)
    this.name = 'ForbiddenError'
  }
}

export class NotFoundError extends Error {
  statusCode = 404
  
  constructor(message = 'Not Found') {
    super(message)
    this.name = 'NotFoundError'
  }
}

export class ConflictError extends Error {
  statusCode = 409
  
  constructor(message = 'Conflict') {
    super(message)
    this.name = 'ConflictError'
  }
}
ERROR

# PART 8: Request validation middleware
echo -e "${GREEN}Creating validation middleware...${NC}"
cat > backend/services/api-gateway/src/middleware/validation.ts << 'VALIDATION'
import { FastifyRequest, FastifyReply } from 'fastify'
import { z, ZodSchema } from 'zod'
import { ValidationError } from './errorHandler'

interface ValidationSchemas {
  body?: ZodSchema
  query?: ZodSchema
  params?: ZodSchema
  headers?: ZodSchema
}

export function validateRequest(schemas: ValidationSchemas) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      // Validate body
      if (schemas.body && request.body) {
        request.body = schemas.body.parse(request.body)
      }

      // Validate query
      if (schemas.query && request.query) {
        request.query = schemas.query.parse(request.query)
      }

      // Validate params
      if (schemas.params && request.params) {
        request.params = schemas.params.parse(request.params)
      }

      // Validate headers
      if (schemas.headers && request.headers) {
        schemas.headers.parse(request.headers)
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        throw new ValidationError('Validation failed', error.errors)
      }
      throw error
    }
  }
}

// Common validation schemas
export const schemas = {
  // ID validation
  id: z.string().uuid(),
  
  // Pagination
  pagination: z.object({
    page: z.string().optional().transform((val) => parseInt(val || '1', 10)),
    limit: z.string().optional().transform((val) => parseInt(val || '10', 10)),
    sortBy: z.string().optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
  }),
  
  // Email
  email: z.string().email(),
  
  // Password (min 8 chars, 1 uppercase, 1 lowercase, 1 number)
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
}
VALIDATION

# PART 9: Utility files
echo -e "${GREEN}Creating utility files...${NC}"

# Logger utility
cat > backend/services/api-gateway/src/utils/logger.ts << 'LOGGER'
import pino from 'pino'
import { config } from '../config'

export const logger = pino({
  level: config.LOG_LEVEL,
  transport:
    config.NODE_ENV === 'development'
      ? {
          target: 'pino-pretty',
          options: {
            translateTime: 'HH:MM:ss Z',
            ignore: 'pid,hostname',
            colorize: true,
          },
        }
      : undefined,
  serializers: {
    req: (req) => ({
      method: req.method,
      url: req.url,
      headers: req.headers,
      hostname: req.hostname,
      remoteAddress: req.ip,
    }),
    res: (res) => ({
      statusCode: res.statusCode,
    }),
  },
})
LOGGER

# Database utility
cat > backend/services/api-gateway/src/utils/database.ts << 'DATABASE'
import { logger } from './logger'

// Placeholder for database connection
// Replace with your actual database client (Prisma, TypeORM, etc.)
export async function connectDatabase() {
  try {
    logger.info('Connecting to database...')
    // Add your database connection logic here
    // For example, with Prisma:
    // const prisma = new PrismaClient()
    // await prisma.$connect()
    logger.info('Database connected successfully')
  } catch (error) {
    logger.error(error, 'Failed to connect to database')
    throw error
  }
}

export async function disconnectDatabase() {
  try {
    logger.info('Disconnecting from database...')
    // Add your database disconnection logic here
    logger.info('Database disconnected successfully')
  } catch (error) {
    logger.error(error, 'Failed to disconnect from database')
    throw error
  }
}
DATABASE

# PART 10: Route files
echo -e "${GREEN}Creating route files...${NC}"

# Health routes
cat > backend/services/api-gateway/src/routes/health.ts << 'HEALTH'
import { FastifyPluginAsync } from 'fastify'

export const healthRoutes: FastifyPluginAsync = async (fastify) => {
  fastify.get('/', {
    schema: {
      description: 'Health check endpoint',
      tags: ['health'],
      response: {
        200: {
          type: 'object',
          properties: {
            status: { type: 'string' },
            timestamp: { type: 'string' },
            uptime: { type: 'number' },
            service: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      service: 'api-gateway',
    }
  })

  fastify.get('/live', async (request, reply) => {
    return { status: 'live' }
  })

  fastify.get('/ready', async (request, reply) => {
    // Check database connection, external services, etc.
    return { status: 'ready' }
  })
}
HEALTH

# Auth routes
cat > backend/services/api-gateway/src/routes/auth.ts << 'AUTHROUTES'
import { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { validateRequest, schemas } from '../middleware/validation'
import { UnauthorizedError, ConflictError } from '../middleware/errorHandler'

const loginSchema = z.object({
  email: schemas.email,
  password: z.string(),
})

const registerSchema = z.object({
  email: schemas.email,
  password: schemas.password,
  name: z.string().min(2).max(100),
})

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  // Register
  fastify.post('/register', {
    preHandler: validateRequest({ body: registerSchema }),
    schema: {
      description: 'Register a new user',
      tags: ['auth'],
      body: {
        type: 'object',
        required: ['email', 'password', 'name'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 8 },
          name: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password, name } = request.body as z.infer<typeof registerSchema>
    
    // Check if user exists (implement your logic)
    // const existingUser = await findUserByEmail(email)
    // if (existingUser) {
    //   throw new ConflictError('User already exists')
    // }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10)
    
    // Create user (implement your logic)
    // const user = await createUser({ email, password: hashedPassword, name })
    
    // Generate token
    const token = await reply.jwtSign({ 
      id: 'user-id', 
      email, 
      role: 'user' 
    })
    
    return {
      token,
      user: { id: 'user-id', email, name, role: 'user' },
    }
  })

  // Login
  fastify.post('/login', {
    preHandler: validateRequest({ body: loginSchema }),
    schema: {
      description: 'Login with email and password',
      tags: ['auth'],
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password } = request.body as z.infer<typeof loginSchema>
    
    // Find user (implement your logic)
    // const user = await findUserByEmail(email)
    // if (!user) {
    //   throw new UnauthorizedError('Invalid credentials')
    // }
    
    // Verify password
    // const isValid = await bcrypt.compare(password, user.password)
    // if (!isValid) {
    //   throw new UnauthorizedError('Invalid credentials')
    // }
    
    // Generate token
    const token = await reply.jwtSign({ 
      id: 'user-id', 
      email, 
      role: 'user' 
    })
    
    return {
      token,
      user: { id: 'user-id', email, role: 'user' },
    }
  })
}
AUTHROUTES

# API routes
cat > backend/services/api-gateway/src/routes/api.ts << 'APIROUTES'
import { FastifyPluginAsync } from 'fastify'
import { authenticate, authorizeRoles } from '../middleware/auth'
import { validateRequest, schemas } from '../middleware/validation'

export const apiRoutes: FastifyPluginAsync = async (fastify) => {
  // Public endpoint
  fastify.get('/status', async (request, reply) => {
    return {
      message: 'API Gateway is running',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    }
  })

  // Protected endpoint
  fastify.get('/profile', {
    preHandler: authenticate,
    schema: {
      description: 'Get user profile',
      tags: ['api'],
      security: [{ bearerAuth: [] }],
    },
  }, async (request, reply) => {
    return {
      user: request.user,
    }
  })

  // Admin only endpoint
  fastify.get('/admin', {
    preHandler: authorizeRoles('admin'),
    schema: {
      description: 'Admin only endpoint',
      tags: ['api'],
      security: [{ bearerAuth: [] }],
    },
  }, async (request, reply) => {
    return {
      message: 'Admin access granted',
      user: request.user,
    }
  })

  // Example CRUD endpoint with validation
  fastify.get('/items', {
    preHandler: validateRequest({ query: schemas.pagination }),
    schema: {
      description: 'Get paginated items',
      tags: ['api'],
      querystring: {
        type: 'object',
        properties: {
          page: { type: 'number', default: 1 },
          limit: { type: 'number', default: 10 },
          sortBy: { type: 'string' },
          sortOrder: { type: 'string', enum: ['asc', 'desc'] },
        },
      },
    },
  }, async (request, reply) => {
    const { page, limit, sortBy, sortOrder } = request.query as any
    
    return {
      items: [],
      pagination: {
        page,
        limit,
        total: 0,
        totalPages: 0,
      },
    }
  })
}
APIROUTES

# PART 11: Environment variables template
echo -e "${GREEN}Creating environment variables template...${NC}"
cat > backend/services/api-gateway/.env.example << 'ENV'
# Environment
NODE_ENV=development

# Server
PORT=8080
HOST=0.0.0.0

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/engineering_app

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars
JWT_EXPIRY=7d
JWT_REFRESH_EXPIRY=30d

# CORS
CORS_ORIGIN=http://localhost:3000

# Rate Limiting
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=15 minutes

# Logging
LOG_LEVEL=info

# API Keys (optional)
API_KEY=

# Email Configuration (optional)
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
ENV

# Copy .env.example to .env
cp backend/services/api-gateway/.env.example backend/services/api-gateway/.env

# PART 12: Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
cd backend/services/api-gateway
npm install
cd ../../..

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}     Backend Core Services Setup Complete!     ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Created files:${NC}"
echo "  ✓ backend/services/api-gateway/package.json"
echo "  ✓ backend/services/api-gateway/tsconfig.json"
echo "  ✓ backend/services/api-gateway/src/app.ts"
echo "  ✓ backend/services/api-gateway/src/server.ts"
echo "  ✓ backend/services/api-gateway/src/config/index.ts"
echo "  ✓ backend/services/api-gateway/src/middleware/auth.ts"
echo "  ✓ backend/services/api-gateway/src/middleware/errorHandler.ts"
echo "  ✓ backend/services/api-gateway/src/middleware/validation.ts"
echo "  ✓ backend/services/api-gateway/src/routes/health.ts"
echo "  ✓ backend/services/api-gateway/src/routes/auth.ts"
echo "  ✓ backend/services/api-gateway/src/routes/api.ts"
echo "  ✓ backend/services/api-gateway/src/utils/logger.ts"
echo "  ✓ backend/services/api-gateway/src/utils/database.ts"
echo "  ✓ backend/services/api-gateway/.env.example"
echo "  ✓ backend/services/api-gateway/.env"
echo ""
echo -e "${YELLOW}Features configured:${NC}"
echo "  • Fastify framework with TypeScript"
echo "  • JWT authentication with role-based access"
echo "  • Request validation with Zod"
echo "  • Rate limiting (100 requests/15 min)"
echo "  • CORS configuration"
echo "  • Helmet security headers"
echo "  • Response compression"
echo "  • Swagger API documentation"
echo "  • Structured error handling"
echo "  • Request/Response logging with Pino"
echo "  • Health check endpoints"
echo ""
echo -e "${YELLOW}Available endpoints:${NC}"
echo "  GET  /health          - Health check"
echo "  GET  /health/live     - Liveness probe"
echo "  GET  /health/ready    - Readiness probe"
echo "  POST /auth/register   - User registration"
echo "  POST /auth/login      - User login"
echo "  GET  /api/v1/status   - API status (public)"
echo "  GET  /api/v1/profile  - User profile (authenticated)"
echo "  GET  /api/v1/admin    - Admin endpoint (admin role)"
echo "  GET  /api/v1/items    - Paginated items example"
echo "  GET  /documentation   - Swagger UI (dev only)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Configure environment variables:"
echo "   ${BLUE}cd backend/services/api-gateway${NC}"
echo "   ${BLUE}nano .env${NC}"
echo "   Update JWT_SECRET and DATABASE_URL"
echo ""
echo "2. Start the API Gateway:"
echo "   ${BLUE}npm run dev${NC}"
echo ""
echo "3. Test the service:"
echo "   ${BLUE}curl http://localhost:8080/health${NC}"
echo ""
echo "4. View API documentation:"
echo "   Open ${BLUE}http://localhost:8080/documentation${NC}"
echo ""
echo "5. Test authentication:"
echo "   Register: ${BLUE}curl -X POST http://localhost:8080/auth/register \\${NC}"
echo "            ${BLUE}  -H 'Content-Type: application/json' \\${NC}"
echo "            ${BLUE}  -d '{\"email\":\"test@example.com\",\"password\":\"Test1234\",\"name\":\"Test User\"}'${NC}"
echo ""
echo -e "${GREEN}Your API Gateway is ready for development!${NC}"

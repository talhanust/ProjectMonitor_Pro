#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Complete Monorepo Setup & Fix Script       ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "frontend" ]; then
    echo -e "${RED}Error: Not in project root directory!${NC}"
    exit 1
fi

# PART 1: FIX FRONTEND NEXT.JS CONFIGURATION
print_section "PART 1: Fixing Frontend Configuration"

cd frontend

echo -e "${GREEN}Fixing next.config.js${NC}"
cat > next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  compress: true,
  
  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
  },

  images: {
    domains: ['localhost'],
    formats: ['image/avif', 'image/webp'],
  },
}

module.exports = nextConfig
NEXTCONFIG

# Disable telemetry via CLI
echo -e "${GREEN}Disabling Next.js telemetry${NC}"
npx next telemetry disable 2>/dev/null || true

# Create missing directories
mkdir -p app/api
mkdir -p app/auth
mkdir -p src/components
mkdir -p src/lib
mkdir -p src/hooks
mkdir -p src/utils
mkdir -p src/types
mkdir -p src/services
mkdir -p public/images

# Create types file
echo -e "${GREEN}Creating type definitions${NC}"
cat > src/types/index.ts << 'TYPES'
// Global type definitions
export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'user' | 'guest'
}

export interface Project {
  id: string
  title: string
  description: string
  status: 'active' | 'completed' | 'archived'
  createdAt: Date
  updatedAt: Date
}

export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: string
  message?: string
}
TYPES

# Create utilities
echo -e "${GREEN}Creating utility functions${NC}"
cat > src/utils/index.ts << 'UTILS'
// Utility functions
export const cn = (...classes: (string | undefined | boolean)[]) => {
  return classes.filter(Boolean).join(' ')
}

export const formatDate = (date: Date | string): string => {
  const d = new Date(date)
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

export const sleep = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms))
}
UTILS

# Create API health route
echo -e "${GREEN}Creating API health route${NC}"
mkdir -p app/api/health
cat > app/api/health/route.ts << 'APIROUTE'
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'frontend',
    version: '1.0.0',
  })
}
APIROUTE

cd ..

# PART 2: SET UP BACKEND SERVICE
print_section "PART 2: Setting Up Backend API Service"

# Ensure backend directory exists
mkdir -p backend/services/api/src/config
mkdir -p backend/services/api/src/controllers
mkdir -p backend/services/api/src/services
mkdir -p backend/services/api/src/routes
mkdir -p backend/services/api/src/middleware
mkdir -p backend/services/api/src/utils
mkdir -p backend/services/api/prisma

echo -e "${GREEN}Creating backend package.json${NC}"
cat > backend/services/api/package.json << 'BACKENDPKG'
{
  "name": "@backend/api",
  "version": "1.0.0",
  "private": true,
  "description": "Backend API service for engineering platform",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "lint": "eslint . --ext ts --report-unused-disable-directives --max-warnings 0",
    "typecheck": "tsc --noEmit",
    "clean": "rimraf dist node_modules .turbo",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:migrate:prod": "prisma migrate deploy",
    "db:studio": "prisma studio"
  },
  "dependencies": {
    "@fastify/cors": "^8.5.0",
    "@fastify/helmet": "^11.1.1",
    "@fastify/jwt": "^7.2.4",
    "@fastify/rate-limit": "^9.1.0",
    "@prisma/client": "^5.8.0",
    "dotenv": "^16.3.1",
    "fastify": "^4.25.2",
    "pino": "^8.17.2",
    "pino-pretty": "^10.3.1",
    "zod": "^3.22.4",
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "@types/bcryptjs": "^2.4.6",
    "@vitest/ui": "^1.2.0",
    "prisma": "^5.8.0",
    "tsx": "^4.7.0",
    "vitest": "^1.2.0",
    "typescript": "^5.3.3",
    "eslint": "^8.56.0",
    "@typescript-eslint/eslint-plugin": "^6.19.0",
    "@typescript-eslint/parser": "^6.19.0"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
BACKENDPKG

echo -e "${GREEN}Creating backend TypeScript config${NC}"
cat > backend/services/api/tsconfig.json << 'BACKENDTS'
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
      "@controllers/*": ["./src/controllers/*"],
      "@services/*": ["./src/services/*"],
      "@routes/*": ["./src/routes/*"],
      "@middleware/*": ["./src/middleware/*"],
      "@utils/*": ["./src/utils/*"],
      "@types/*": ["./src/types/*"]
    },
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true,
    "allowSyntheticDefaultImports": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "coverage"]
}
BACKENDTS

echo -e "${GREEN}Creating backend server file${NC}"
cat > backend/services/api/src/index.ts << 'BACKENDINDEX'
import Fastify from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import rateLimit from '@fastify/rate-limit'
import { config } from './config/env'
import { logger } from './utils/logger'

const server = Fastify({
  logger,
})

async function bootstrap() {
  try {
    // Register plugins
    await server.register(helmet)
    await server.register(cors, {
      origin: config.CORS_ORIGIN,
      credentials: true,
    })
    await server.register(rateLimit, {
      max: 100,
      timeWindow: '1 minute',
    })

    // Health check route
    server.get('/health', async () => {
      return { 
        status: 'ok', 
        service: 'backend-api',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      }
    })

    // API routes
    server.get('/api/v1/status', async () => {
      return {
        message: 'Engineering Platform API',
        version: '1.0.0',
        environment: config.NODE_ENV,
      }
    })

    // Start server
    await server.listen({ port: config.PORT, host: '0.0.0.0' })
    console.log(`Server running at http://localhost:${config.PORT}`)
  } catch (err) {
    server.log.error(err)
    process.exit(1)
  }
}

bootstrap()
BACKENDINDEX

echo -e "${GREEN}Creating backend config${NC}"
cat > backend/services/api/src/config/env.ts << 'BACKENDCONFIG'
import { z } from 'zod'
import dotenv from 'dotenv'

dotenv.config()

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('8080').transform(Number),
  DATABASE_URL: z.string().default('postgresql://localhost:5432/engineering_app'),
  JWT_SECRET: z.string().default('your-secret-key-change-in-production'),
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
})

export const config = envSchema.parse(process.env)
BACKENDCONFIG

echo -e "${GREEN}Creating logger utility${NC}"
cat > backend/services/api/src/utils/logger.ts << 'LOGGER'
import pino from 'pino'

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'development' 
    ? {
        target: 'pino-pretty',
        options: {
          translateTime: 'HH:MM:ss Z',
          ignore: 'pid,hostname',
          colorize: true,
        },
      }
    : undefined,
})
LOGGER

echo -e "${GREEN}Creating Prisma schema${NC}"
cat > backend/services/api/prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String    @id @default(cuid())
  email     String    @unique
  name      String?
  password  String
  role      Role      @default(USER)
  createdAt DateTime  @default(now())
  updatedAt DateTime  @updatedAt
  projects  Project[]
}

model Project {
  id          String   @id @default(cuid())
  title       String
  description String?
  status      Status   @default(ACTIVE)
  userId      String
  user        User     @relation(fields: [userId], references: [id])
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

enum Role {
  USER
  ADMIN
}

enum Status {
  ACTIVE
  COMPLETED
  ARCHIVED
}
PRISMA

# PART 3: CREATE DOCUMENTATION
print_section "PART 3: Creating Documentation"

mkdir -p docs/api
mkdir -p docs/adr
mkdir -p docs/guides

echo -e "${GREEN}Creating API documentation${NC}"
cat > docs/api/README.md << 'APIDOC'
# API Documentation

## Base URL
- Development: http://localhost:8080
- Production: TBD

## Authentication
All authenticated endpoints require a JWT token in the Authorization header:
Authorization: Bearer <token>

## Endpoints

### Health Check
GET /health
Returns the health status of the API.

### Status
GET /api/v1/status
Returns API version and environment information.

## Error Responses
All errors follow this format:
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
Rate Limiting

100 requests per minute per IP
Headers included in response:

X-RateLimit-Limit
X-RateLimit-Remaining
X-RateLimit-Reset
APIDOC

# PART 4: CREATE SCRIPTS
print_section "PART 4: Creating Build and Deployment Scripts"

mkdir -p scripts/build
mkdir -p scripts/deploy

echo -e "${GREEN}Creating build script${NC}"
cat > scripts/build/build-all.sh << 'BUILDSCRIPT'
#!/bin/bash

echo "Building all packages..."
# Build shared packages first
echo "Building shared packages..."
npm run build -w @packages/shared 2>/dev/null || echo "Shared package not configured"
# Build backend
echo "Building backend..."
npm run build -w @backend/api
# Build frontend
echo "Building frontend..."
npm run build -w frontend
echo "Build complete!"
BUILDSCRIPT

chmod +x scripts/build/build-all.sh

# PART 5: CREATE DEVELOPMENT TOOLS
print_section "PART 5: Creating Development Tools"

mkdir -p tools

echo -e "${GREEN}Creating development helper script${NC}"
cat > tools/dev-helper.sh << 'DEVHELPER'
#!/bin/bash

case "$1" in
"clean")
echo "Cleaning all node_modules and build artifacts..."
find . -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null
find . -name "dist" -type d -prune -exec rm -rf {} + 2>/dev/null
find . -name ".next" -type d -prune -exec rm -rf {} + 2>/dev/null
echo "Clean complete!"
;;
"install")
echo "Installing all dependencies..."
npm install
echo "Install complete!"
;;
"typecheck")
echo "Running type check..."
npm run typecheck
;;
"test")
echo "Running all tests..."
npm test
;;
*)
echo "Usage: $0 {clean|install|typecheck|test}"
exit 1
;;
esac
DEVHELPER

chmod +x tools/dev-helper.sh

# PART 6: FINAL SETUP
print_section "PART 6: Final Setup & Installation"

echo -e "${GREEN}Installing dependencies...${NC}"
npm install

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}          Setup Complete!                      ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

echo -e "${YELLOW}What was set up:${NC}"
echo "  - Frontend (Next.js 15 with React 18)"
echo "  - Backend API (Fastify with TypeScript)"
echo "  - Database schema (Prisma)"
echo "  - Documentation structure"
echo "  - Build scripts"
echo "  - Development tools"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Start the development servers:"
echo "   ${BLUE}npm run dev${NC}"
echo ""
echo "2. Frontend will be available at:"
echo "   ${BLUE}http://localhost:3000${NC}"
echo ""
echo "3. Backend API will be available at:"
echo "   ${BLUE}http://localhost:8080${NC}"
echo ""
echo "4. Set up your database (optional):"
echo "   - Update DATABASE_URL in .env"
echo "   - Run: ${BLUE}cd backend/services/api && npx prisma migrate dev${NC}"
echo ""

echo -e "${GREEN}Your monorepo is ready for development!${NC}"
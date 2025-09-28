#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}      Database Layer Foundation Setup          ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ]; then
    echo -e "${RED}Error: Not in project root directory!${NC}"
    exit 1
fi

# Create shared database directory structure
echo -e "${GREEN}Creating shared database directory structure...${NC}"
mkdir -p backend/services/shared/prisma
mkdir -p backend/services/shared/database/migrations
mkdir -p backend/services/shared/database/repositories
mkdir -p backend/services/shared/database/types

# PART 1: Create docker-compose.yml for PostgreSQL
echo -e "${GREEN}Creating docker-compose.yml...${NC}"
cat > docker-compose.yml << 'DOCKER'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: engineering_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-engineering_app}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/services/shared/database/migrations:/docker-entrypoint-initdb.d
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-postgres}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: engineering_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  adminer:
    image: adminer
    container_name: engineering_adminer
    restart: unless-stopped
    ports:
      - 8090:8080
    environment:
      ADMINER_DEFAULT_SERVER: postgres
    depends_on:
      - postgres

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: engineering_network
DOCKER

# PART 2: Create Prisma schema
echo -e "${GREEN}Creating Prisma schema...${NC}"
cat > backend/services/shared/prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// Enums
enum UserRole {
  USER
  ADMIN
  MANAGER
}

enum ProjectStatus {
  PLANNING
  IN_PROGRESS
  ON_HOLD
  COMPLETED
  CANCELLED
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  IN_REVIEW
  DONE
  BLOCKED
}

enum TaskPriority {
  LOW
  MEDIUM
  HIGH
  CRITICAL
}

// User model
model User {
  id              String          @id @default(cuid())
  email           String          @unique
  password        String
  name            String?
  avatar          String?
  role            UserRole        @default(USER)
  isActive        Boolean         @default(true)
  emailVerified   DateTime?
  lastLogin       DateTime?
  
  // Relations
  projects        Project[]       @relation("ProjectOwner")
  projectMembers  ProjectMember[]
  tasks           Task[]          @relation("TaskAssignee")
  createdTasks    Task[]          @relation("TaskCreator")
  comments        Comment[]
  attachments     Attachment[]
  activities      Activity[]
  notifications   Notification[]
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  
  @@index([email])
  @@index([role])
  @@index([isActive])
}

// Project model
model Project {
  id              String          @id @default(cuid())
  name            String
  description     String?
  code            String          @unique
  status          ProjectStatus   @default(PLANNING)
  startDate       DateTime?
  endDate         DateTime?
  budget          Decimal?        @db.Money
  
  // Relations
  owner           User            @relation("ProjectOwner", fields: [ownerId], references: [id])
  ownerId         String
  members         ProjectMember[]
  tasks           Task[]
  milestones      Milestone[]
  documents       Document[]
  activities      Activity[]
  tags            Tag[]
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  
  @@index([code])
  @@index([status])
  @@index([ownerId])
}

// Project Member junction table
model ProjectMember {
  id              String          @id @default(cuid())
  
  project         Project         @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId       String
  
  user            User            @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId          String
  
  role            String          @default("member") // member, lead, viewer
  permissions     Json?           // Custom permissions object
  joinedAt        DateTime        @default(now())
  
  @@unique([projectId, userId])
  @@index([projectId])
  @@index([userId])
}

// Task model
model Task {
  id              String          @id @default(cuid())
  title           String
  description     String?
  code            String          @unique
  status          TaskStatus      @default(TODO)
  priority        TaskPriority    @default(MEDIUM)
  dueDate         DateTime?
  estimatedHours  Float?
  actualHours     Float?
  
  // Relations
  project         Project         @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId       String
  
  assignee        User?           @relation("TaskAssignee", fields: [assigneeId], references: [id])
  assigneeId      String?
  
  creator         User            @relation("TaskCreator", fields: [creatorId], references: [id])
  creatorId       String
  
  milestone       Milestone?      @relation(fields: [milestoneId], references: [id])
  milestoneId     String?
  
  parentTask      Task?           @relation("SubTasks", fields: [parentTaskId], references: [id])
  parentTaskId    String?
  subTasks        Task[]          @relation("SubTasks")
  
  comments        Comment[]
  attachments     Attachment[]
  activities      Activity[]
  tags            Tag[]
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  completedAt     DateTime?
  
  @@index([projectId])
  @@index([assigneeId])
  @@index([status])
  @@index([priority])
  @@index([code])
}

// Milestone model
model Milestone {
  id              String          @id @default(cuid())
  name            String
  description     String?
  dueDate         DateTime
  
  // Relations
  project         Project         @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId       String
  
  tasks           Task[]
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  completedAt     DateTime?
  
  @@index([projectId])
}

// Comment model
model Comment {
  id              String          @id @default(cuid())
  content         String
  
  // Relations
  task            Task            @relation(fields: [taskId], references: [id], onDelete: Cascade)
  taskId          String
  
  author          User            @relation(fields: [authorId], references: [id])
  authorId        String
  
  parentComment   Comment?        @relation("CommentReplies", fields: [parentCommentId], references: [id])
  parentCommentId String?
  replies         Comment[]       @relation("CommentReplies")
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  
  @@index([taskId])
  @@index([authorId])
}

// Document model
model Document {
  id              String          @id @default(cuid())
  name            String
  description     String?
  url             String
  mimeType        String
  size            Int
  
  // Relations
  project         Project         @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId       String
  
  uploadedBy      User            @relation(fields: [uploadedById], references: [id])
  uploadedById    String
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  
  @@index([projectId])
}

// Attachment model
model Attachment {
  id              String          @id @default(cuid())
  filename        String
  url             String
  mimeType        String
  size            Int
  
  // Relations
  task            Task?           @relation(fields: [taskId], references: [id], onDelete: Cascade)
  taskId          String?
  
  uploadedBy      User            @relation(fields: [uploadedById], references: [id])
  uploadedById    String
  
  // Timestamps
  createdAt       DateTime        @default(now())
  
  @@index([taskId])
}

// Activity/Audit Log model
model Activity {
  id              String          @id @default(cuid())
  action          String          // created, updated, deleted, etc.
  entityType      String          // project, task, comment, etc.
  entityId        String
  metadata        Json?           // Additional data about the action
  
  // Relations
  user            User            @relation(fields: [userId], references: [id])
  userId          String
  
  project         Project?        @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId       String?
  
  task            Task?           @relation(fields: [taskId], references: [id], onDelete: Cascade)
  taskId          String?
  
  // Timestamps
  createdAt       DateTime        @default(now())
  
  @@index([userId])
  @@index([projectId])
  @@index([taskId])
  @@index([entityType, entityId])
  @@index([createdAt])
}

// Notification model
model Notification {
  id              String          @id @default(cuid())
  type            String          // task_assigned, comment_added, etc.
  title           String
  message         String
  data            Json?           // Additional notification data
  read            Boolean         @default(false)
  
  // Relations
  user            User            @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId          String
  
  // Timestamps
  createdAt       DateTime        @default(now())
  readAt          DateTime?
  
  @@index([userId, read])
  @@index([createdAt])
}

// Tag model
model Tag {
  id              String          @id @default(cuid())
  name            String          @unique
  color           String?
  
  // Relations
  projects        Project[]
  tasks           Task[]
  
  // Timestamps
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt
  
  @@index([name])
}

// User model extension for Document relation
model User {
  documents       Document[]
}
PRISMA

# PART 3: Create seed file
echo -e "${GREEN}Creating database seed file...${NC}"
cat > backend/services/shared/prisma/seed.ts << 'SEED'
import { PrismaClient } from '@prisma/client'
import * as bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Starting database seed...')

  // Create admin user
  const adminPassword = await bcrypt.hash('Admin123!', 10)
  const admin = await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      password: adminPassword,
      name: 'Admin User',
      role: 'ADMIN',
      emailVerified: new Date(),
    },
  })
  console.log('✓ Admin user created')

  // Create regular users
  const userPassword = await bcrypt.hash('User123!', 10)
  const users = await Promise.all([
    prisma.user.upsert({
      where: { email: 'john.doe@example.com' },
      update: {},
      create: {
        email: 'john.doe@example.com',
        password: userPassword,
        name: 'John Doe',
        role: 'USER',
        emailVerified: new Date(),
      },
    }),
    prisma.user.upsert({
      where: { email: 'jane.smith@example.com' },
      update: {},
      create: {
        email: 'jane.smith@example.com',
        password: userPassword,
        name: 'Jane Smith',
        role: 'MANAGER',
        emailVerified: new Date(),
      },
    }),
  ])
  console.log('✓ Regular users created')

  // Create sample projects
  const project1 = await prisma.project.create({
    data: {
      name: 'Website Redesign',
      description: 'Complete redesign of company website',
      code: 'WEB-2024',
      status: 'IN_PROGRESS',
      ownerId: admin.id,
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-06-30'),
      members: {
        create: [
          { userId: users[0].id, role: 'lead' },
          { userId: users[1].id, role: 'member' },
        ],
      },
    },
  })

  const project2 = await prisma.project.create({
    data: {
      name: 'Mobile App Development',
      description: 'Native mobile app for iOS and Android',
      code: 'MOB-2024',
      status: 'PLANNING',
      ownerId: users[1].id,
      members: {
        create: [
          { userId: users[0].id, role: 'member' },
          { userId: admin.id, role: 'viewer' },
        ],
      },
    },
  })
  console.log('✓ Sample projects created')

  // Create milestones
  const milestone1 = await prisma.milestone.create({
    data: {
      name: 'Phase 1 - Design',
      description: 'Complete design mockups and prototypes',
      dueDate: new Date('2024-02-28'),
      projectId: project1.id,
    },
  })
  console.log('✓ Milestones created')

  // Create sample tasks
  const tasks = await Promise.all([
    prisma.task.create({
      data: {
        title: 'Create wireframes',
        description: 'Design initial wireframes for all pages',
        code: 'TASK-001',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        projectId: project1.id,
        assigneeId: users[0].id,
        creatorId: admin.id,
        milestoneId: milestone1.id,
        estimatedHours: 16,
      },
    }),
    prisma.task.create({
      data: {
        title: 'Setup development environment',
        description: 'Configure development tools and dependencies',
        code: 'TASK-002',
        status: 'DONE',
        priority: 'MEDIUM',
        projectId: project1.id,
        assigneeId: users[1].id,
        creatorId: admin.id,
        estimatedHours: 8,
        actualHours: 6,
        completedAt: new Date(),
      },
    }),
    prisma.task.create({
      data: {
        title: 'Market research',
        description: 'Research competitor apps and features',
        code: 'TASK-003',
        status: 'TODO',
        priority: 'HIGH',
        projectId: project2.id,
        assigneeId: users[0].id,
        creatorId: users[1].id,
        estimatedHours: 24,
      },
    }),
  ])
  console.log('✓ Sample tasks created')

  // Create comments
  await prisma.comment.create({
    data: {
      content: 'Looking good so far! Keep up the great work.',
      taskId: tasks[0].id,
      authorId: admin.id,
    },
  })
  console.log('✓ Sample comments created')

  // Create tags
  const tags = await Promise.all([
    prisma.tag.upsert({
      where: { name: 'urgent' },
      update: {},
      create: { name: 'urgent', color: '#FF0000' },
    }),
    prisma.tag.upsert({
      where: { name: 'frontend' },
      update: {},
      create: { name: 'frontend', color: '#00FF00' },
    }),
    prisma.tag.upsert({
      where: { name: 'backend' },
      update: {},
      create: { name: 'backend', color: '#0000FF' },
    }),
  ])
  console.log('✓ Tags created')

  // Create activities
  await prisma.activity.create({
    data: {
      action: 'created',
      entityType: 'project',
      entityId: project1.id,
      userId: admin.id,
      projectId: project1.id,
      metadata: { projectName: project1.name },
    },
  })
  console.log('✓ Sample activities created')

  // Create notifications
  await prisma.notification.create({
    data: {
      type: 'task_assigned',
      title: 'New Task Assigned',
      message: 'You have been assigned to "Create wireframes"',
      userId: users[0].id,
      data: { taskId: tasks[0].id },
    },
  })
  console.log('✓ Sample notifications created')

  console.log('✅ Database seed completed!')
}

main()
  .catch((e) => {
    console.error('❌ Error during seed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
SEED

# PART 4: Create database connection manager
echo -e "${GREEN}Creating database connection manager...${NC}"
cat > backend/services/shared/database/connection.ts << 'CONNECTION'
import { PrismaClient } from '@prisma/client'

declare global {
  var prisma: PrismaClient | undefined
}

export const prisma = global.prisma || new PrismaClient({
  log: process.env.NODE_ENV === 'development' 
    ? ['query', 'info', 'warn', 'error']
    : ['error'],
})

if (process.env.NODE_ENV !== 'production') {
  global.prisma = prisma
}

// Connection helper
export async function connectDatabase(): Promise<void> {
  try {
    await prisma.$connect()
    console.log('✅ Database connected successfully')
  } catch (error) {
    console.error('❌ Database connection failed:', error)
    throw error
  }
}

// Disconnection helper
export async function disconnectDatabase(): Promise<void> {
  try {
    await prisma.$disconnect()
    console.log('✅ Database disconnected successfully')
  } catch (error) {
    console.error('❌ Database disconnection failed:', error)
    throw error
  }
}

// Health check
export async function checkDatabaseHealth(): Promise<boolean> {
  try {
    await prisma.$queryRaw`SELECT 1`
    return true
  } catch (error) {
    return false
  }
}
CONNECTION

# PART 5: Create initial migration SQL
echo -e "${GREEN}Creating initial migration...${NC}"
cat > backend/services/shared/database/migrations/001_initial.sql << 'MIGRATION'
-- Initial database setup
-- This file is for reference. Prisma will manage the actual migrations

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types if needed
-- CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'MANAGER');

-- Add any custom functions
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add any custom indexes or constraints not handled by Prisma
-- These will be applied after Prisma migrations
MIGRATION

# PART 6: Create database utilities export
echo -e "${GREEN}Creating database utilities export...${NC}"
cat > backend/services/shared/database/index.ts << 'INDEX'
export { 
  prisma, 
  connectDatabase, 
  disconnectDatabase, 
  checkDatabaseHealth 
} from './connection'

export { PrismaClient } from '@prisma/client'
export type { User, Project, Task, Comment } from '@prisma/client'

// Re-export all Prisma types
export * from '@prisma/client'
INDEX

# PART 7: Create shared package.json
echo -e "${GREEN}Creating shared package.json...${NC}"
cat > backend/services/shared/package.json << 'PACKAGE'
{
  "name": "@backend/shared",
  "version": "1.0.0",
  "private": true,
  "description": "Shared database and utilities for backend services",
  "main": "dist/index.js",
  "types": "dist/index.d.ts",
  "scripts": {
    "build": "tsc",
    "dev": "tsc --watch",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:migrate:prod": "prisma migrate deploy",
    "prisma:studio": "prisma studio",
    "prisma:seed": "tsx prisma/seed.ts",
    "prisma:reset": "prisma migrate reset",
    "db:push": "prisma db push",
    "clean": "rimraf dist node_modules"
  },
  "dependencies": {
    "@prisma/client": "^5.8.0",
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/node": "^20.11.0",
    "prisma": "^5.8.0",
    "tsx": "^4.7.0",
    "typescript": "^5.3.3",
    "rimraf": "^5.0.5"
  },
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
PACKAGE

# PART 8: Create tsconfig for shared
echo -e "${GREEN}Creating shared tsconfig...${NC}"
cat > backend/services/shared/tsconfig.json << 'TSCONFIG'
{
  "extends": "../../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": ".",
    "baseUrl": ".",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["database/**/*", "prisma/**/*"],
  "exclude": ["node_modules", "dist"]
}
TSCONFIG

# PART 9: Update .env file
echo -e "${GREEN}Updating .env file...${NC}"
cat >> .env << 'ENV'

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=engineering_app

# Redis
REDIS_URL=redis://localhost:6379
ENV

# PART 10: Update root package.json
echo -e "${GREEN}Updating root package.json workspaces...${NC}"
if ! grep -q "backend/services/shared" package.json; then
  sed -i '/"workspaces":/,/\]/s/\]/,\n    "backend\/services\/shared"\n  ]/' package.json 2>/dev/null || \
  sed -i '' '/"workspaces":/,/\]/s/\]/,\n    "backend\/services\/shared"\n  ]/' package.json
fi

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
cd backend/services/shared
npm install
cd ../../..

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Database Layer Setup Complete!             ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Start PostgreSQL database:"
echo "   ${BLUE}docker-compose up -d postgres${NC}"
echo ""
echo "2. Wait for database to be ready (5-10 seconds), then run migrations:"
echo "   ${BLUE}cd backend/services/shared${NC}"
echo "   ${BLUE}npx prisma migrate dev --name initial${NC}"
echo ""
echo "3. Seed the database:"
echo "   ${BLUE}npm run prisma:seed${NC}"
echo ""
echo "4. (Optional) Open Prisma Studio to view data:"
echo "   ${BLUE}npx prisma studio${NC}"
echo ""
echo "5. (Optional) Access Adminer database UI:"
echo "   Open ${BLUE}http://localhost:8090${NC}"
echo "   Server: postgres"
echo "   Username: postgres"
echo "   Password: postgres"
echo "   Database: engineering_app"
echo ""
echo -e "${YELLOW}Database credentials:${NC}"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: engineering_app"
echo "  Username: postgres"
echo "  Password: postgres"
echo ""
echo -e "${YELLOW}Test users created:${NC}"
echo "  admin@example.com / Admin123!"
echo "  john.doe@example.com / User123!"
echo "  jane.smith@example.com / User123!"
echo ""
echo -e "${GREEN}Your database layer is ready!${NC}"

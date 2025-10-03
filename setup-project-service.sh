#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Setting Up Project Management Module       ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Create project service directory structure
echo -e "${GREEN}Creating project service structure...${NC}"
mkdir -p backend/services/project-service/{src/{controllers,services,repositories,validators,models,utils,routes,middleware},prisma,tests}

cd backend/services/project-service

# Create package.json
echo -e "${GREEN}Creating package.json...${NC}"
cat > package.json << 'PACKAGE'
{
  "name": "@backend/project-service",
  "version": "1.0.0",
  "private": true,
  "description": "Project Management Service",
  "main": "dist/server.js",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "vitest",
    "lint": "eslint . --ext ts --report-unused-disable-directives --max-warnings 0",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "@prisma/client": "^5.8.0",
    "@fastify/cors": "^8.5.0",
    "@fastify/jwt": "^7.2.4",
    "fastify": "^4.25.2",
    "joi": "^17.11.0",
    "dotenv": "^16.3.1",
    "pino": "^8.17.2",
    "pino-pretty": "^10.3.1"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "prisma": "^5.8.0",
    "tsx": "^4.7.0",
    "typescript": "^5.3.3",
    "vitest": "^1.2.0"
  }
}
PACKAGE

# Install dependencies
npm install

# Create TypeScript config
echo -e "${GREEN}Creating tsconfig.json...${NC}"
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
TSCONFIG

# Create .env file
echo -e "${GREEN}Creating .env file...${NC}"
cat > .env << 'ENV'
PORT=8081
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app?schema=public
JWT_SECRET=your-secret-key-here
NODE_ENV=development
ENV

# Create Prisma schema
echo -e "${GREEN}Creating Prisma schema...${NC}"
cat > prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Project {
  id                String    @id @default(cuid())
  projectId         String    @unique // DIR-YYYY-XXXX format
  name              String
  description       String?
  status            String    @default("PLANNING")
  priority          String    @default("MEDIUM")
  budget            Float?
  startDate         DateTime?
  endDate           DateTime?
  actualStartDate   DateTime?
  actualEndDate     DateTime?
  progress          Int       @default(0)
  
  // Location
  location          String?
  gpsLatitude       Float?
  gpsLongitude      Float?
  
  // People
  projectManager    String?
  teamMembers       String[]  @default([])
  stakeholders      String[]  @default([])
  
  // Additional fields
  tags              String[]  @default([])
  attachments       String[]  @default([])
  risks             Json?
  milestones        Json?
  
  createdAt         DateTime  @default(now())
  updatedAt         DateTime  @updatedAt
  createdBy         String?
  updatedBy         String?
  
  @@index([projectId])
  @@index([status])
  @@index([createdAt])
  @@map("projects")
}

model ProjectCounter {
  id        String   @id @default(cuid())
  year      Int
  counter   Int      @default(0)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@unique([year])
  @@map("project_counters")
}
PRISMA

# Create shared types
echo -e "${GREEN}Creating shared project types...${NC}"
mkdir -p ../shared/types
cat > ../shared/types/project.types.ts << 'TYPES'
export interface Project {
  id: string;
  projectId: string;
  name: string;
  description?: string;
  status: ProjectStatus;
  priority: ProjectPriority;
  budget?: number;
  startDate?: Date;
  endDate?: Date;
  actualStartDate?: Date;
  actualEndDate?: Date;
  progress: number;
  location?: string;
  gpsLatitude?: number;
  gpsLongitude?: number;
  projectManager?: string;
  teamMembers: string[];
  stakeholders: string[];
  tags: string[];
  attachments: string[];
  risks?: any;
  milestones?: any;
  createdAt: Date;
  updatedAt: Date;
  createdBy?: string;
  updatedBy?: string;
}

export enum ProjectStatus {
  PLANNING = 'PLANNING',
  IN_PROGRESS = 'IN_PROGRESS',
  ON_HOLD = 'ON_HOLD',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED'
}

export enum ProjectPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL'
}

export interface CreateProjectDTO {
  name: string;
  description?: string;
  status?: ProjectStatus;
  priority?: ProjectPriority;
  budget?: number;
  startDate?: string;
  endDate?: string;
  location?: string;
  gpsLatitude?: number;
  gpsLongitude?: number;
  projectManager?: string;
  teamMembers?: string[];
  stakeholders?: string[];
  tags?: string[];
}

export interface UpdateProjectDTO extends Partial<CreateProjectDTO> {
  actualStartDate?: string;
  actualEndDate?: string;
  progress?: number;
}
TYPES

# Create project model
echo -e "${GREEN}Creating project model...${NC}"
cat > src/models/project.model.ts << 'MODEL'
export * from '../../shared/types/project.types';
MODEL

# Create ID generator utility
echo -e "${GREEN}Creating ID generator...${NC}"
cat > src/utils/idGenerator.ts << 'IDGEN'
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function generateProjectId(): Promise<string> {
  const year = new Date().getFullYear();
  
  // Get or create counter for current year
  const counter = await prisma.projectCounter.upsert({
    where: { year },
    update: { 
      counter: { increment: 1 } 
    },
    create: { 
      year,
      counter: 1 
    }
  });
  
  // Format: DIR-YYYY-XXXX (e.g., DIR-2025-0001)
  const projectId = `DIR-${year}-${String(counter.counter).padStart(4, '0')}`;
  
  return projectId;
}
IDGEN

# Create validation schemas
echo -e "${GREEN}Creating validation schemas...${NC}"
cat > src/validators/projectValidator.ts << 'VALIDATOR'
import Joi from 'joi';

export const createProjectSchema = Joi.object({
  name: Joi.string().min(3).max(200).required(),
  description: Joi.string().max(1000).optional(),
  status: Joi.string()
    .valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED')
    .optional(),
  priority: Joi.string()
    .valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    .optional(),
  budget: Joi.number().positive().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().greater(Joi.ref('startDate')).optional(),
  location: Joi.string().max(500).optional(),
  gpsLatitude: Joi.number().min(-90).max(90).optional(),
  gpsLongitude: Joi.number().min(-180).max(180).optional(),
  projectManager: Joi.string().optional(),
  teamMembers: Joi.array().items(Joi.string()).optional(),
  stakeholders: Joi.array().items(Joi.string()).optional(),
  tags: Joi.array().items(Joi.string()).optional()
});

export const updateProjectSchema = Joi.object({
  name: Joi.string().min(3).max(200).optional(),
  description: Joi.string().max(1000).optional(),
  status: Joi.string()
    .valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED')
    .optional(),
  priority: Joi.string()
    .valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    .optional(),
  budget: Joi.number().positive().optional(),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  actualStartDate: Joi.date().iso().optional(),
  actualEndDate: Joi.date().iso().optional(),
  progress: Joi.number().min(0).max(100).optional(),
  location: Joi.string().max(500).optional(),
  gpsLatitude: Joi.number().min(-90).max(90).optional(),
  gpsLongitude: Joi.number().min(-180).max(180).optional(),
  projectManager: Joi.string().optional(),
  teamMembers: Joi.array().items(Joi.string()).optional(),
  stakeholders: Joi.array().items(Joi.string()).optional(),
  tags: Joi.array().items(Joi.string()).optional()
}).min(1); // At least one field required for update

export const queryProjectsSchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  status: Joi.string()
    .valid('PLANNING', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED')
    .optional(),
  priority: Joi.string()
    .valid('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    .optional(),
  search: Joi.string().optional(),
  sortBy: Joi.string()
    .valid('createdAt', 'updatedAt', 'name', 'projectId', 'startDate')
    .default('createdAt'),
  sortOrder: Joi.string().valid('asc', 'desc').default('desc')
});
VALIDATOR

# Create repository
echo -e "${GREEN}Creating project repository...${NC}"
cat > src/repositories/projectRepository.ts << 'REPOSITORY'
import { PrismaClient, Prisma } from '@prisma/client';
import { CreateProjectDTO, UpdateProjectDTO } from '../models/project.model';

const prisma = new PrismaClient();

export class ProjectRepository {
  async create(data: CreateProjectDTO & { projectId: string, createdBy?: string }) {
    return await prisma.project.create({
      data: {
        ...data,
        startDate: data.startDate ? new Date(data.startDate) : undefined,
        endDate: data.endDate ? new Date(data.endDate) : undefined,
      }
    });
  }

  async findById(id: string) {
    return await prisma.project.findUnique({
      where: { id }
    });
  }

  async findByProjectId(projectId: string) {
    return await prisma.project.findUnique({
      where: { projectId }
    });
  }

  async update(id: string, data: UpdateProjectDTO & { updatedBy?: string }) {
    return await prisma.project.update({
      where: { id },
      data: {
        ...data,
        startDate: data.startDate ? new Date(data.startDate) : undefined,
        endDate: data.endDate ? new Date(data.endDate) : undefined,
        actualStartDate: data.actualStartDate ? new Date(data.actualStartDate) : undefined,
        actualEndDate: data.actualEndDate ? new Date(data.actualEndDate) : undefined,
      }
    });
  }

  async delete(id: string) {
    return await prisma.project.delete({
      where: { id }
    });
  }

  async findMany(options: {
    page: number;
    limit: number;
    status?: string;
    priority?: string;
    search?: string;
    sortBy: string;
    sortOrder: 'asc' | 'desc';
  }) {
    const { page, limit, status, priority, search, sortBy, sortOrder } = options;
    const skip = (page - 1) * limit;

    const where: Prisma.ProjectWhereInput = {};
    
    if (status) where.status = status;
    if (priority) where.priority = priority;
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { projectId: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [projects, total] = await Promise.all([
      prisma.project.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: sortOrder }
      }),
      prisma.project.count({ where })
    ]);

    return {
      projects,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }

  async getStatistics() {
    const [total, byStatus, byPriority] = await Promise.all([
      prisma.project.count(),
      prisma.project.groupBy({
        by: ['status'],
        _count: true
      }),
      prisma.project.groupBy({
        by: ['priority'],
        _count: true
      })
    ]);

    return {
      total,
      byStatus,
      byPriority
    };
  }
}

export const projectRepository = new ProjectRepository();
REPOSITORY

# Create service
echo -e "${GREEN}Creating project service...${NC}"
cat > src/services/projectService.ts << 'SERVICE'
import { projectRepository } from '../repositories/projectRepository';
import { generateProjectId } from '../utils/idGenerator';
import { CreateProjectDTO, UpdateProjectDTO } from '../models/project.model';

export class ProjectService {
  async createProject(data: CreateProjectDTO, userId?: string) {
    // Generate unique project ID
    const projectId = await generateProjectId();
    
    // Create project
    const project = await projectRepository.create({
      ...data,
      projectId,
      createdBy: userId
    });
    
    return project;
  }

  async getProject(id: string) {
    const project = await projectRepository.findById(id);
    if (!project) {
      throw new Error('Project not found');
    }
    return project;
  }

  async getProjectByProjectId(projectId: string) {
    const project = await projectRepository.findByProjectId(projectId);
    if (!project) {
      throw new Error('Project not found');
    }
    return project;
  }

  async updateProject(id: string, data: UpdateProjectDTO, userId?: string) {
    // Check if project exists
    await this.getProject(id);
    
    // Update project
    const project = await projectRepository.update(id, {
      ...data,
      updatedBy: userId
    });
    
    return project;
  }

  async deleteProject(id: string) {
    // Check if project exists
    await this.getProject(id);
    
    // Delete project
    await projectRepository.delete(id);
    
    return { message: 'Project deleted successfully' };
  }

  async listProjects(query: any) {
    return await projectRepository.findMany(query);
  }

  async getProjectStatistics() {
    return await projectRepository.getStatistics();
  }
}

export const projectService = new ProjectService();
SERVICE

# Create controller
echo -e "${GREEN}Creating project controller...${NC}"
cat > src/controllers/projectController.ts << 'CONTROLLER'
import { FastifyRequest, FastifyReply } from 'fastify';
import { projectService } from '../services/projectService';
import { 
  createProjectSchema, 
  updateProjectSchema, 
  queryProjectsSchema 
} from '../validators/projectValidator';

export class ProjectController {
  async createProject(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { error, value } = createProjectSchema.validate(request.body);
      if (error) {
        return reply.status(400).send({ 
          error: 'Validation error', 
          details: error.details 
        });
      }

      const userId = (request as any).user?.id;
      const project = await projectService.createProject(value, userId);
      
      return reply.status(201).send(project);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Failed to create project',
        message: error.message 
      });
    }
  }

  async getProject(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const project = await projectService.getProject(id);
      return reply.send(project);
    } catch (error: any) {
      if (error.message === 'Project not found') {
        return reply.status(404).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to get project',
        message: error.message 
      });
    }
  }

  async updateProject(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const { error, value } = updateProjectSchema.validate(request.body);
      
      if (error) {
        return reply.status(400).send({ 
          error: 'Validation error', 
          details: error.details 
        });
      }

      const userId = (request as any).user?.id;
      const project = await projectService.updateProject(id, value, userId);
      
      return reply.send(project);
    } catch (error: any) {
      if (error.message === 'Project not found') {
        return reply.status(404).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to update project',
        message: error.message 
      });
    }
  }

  async deleteProject(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const result = await projectService.deleteProject(id);
      return reply.send(result);
    } catch (error: any) {
      if (error.message === 'Project not found') {
        return reply.status(404).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to delete project',
        message: error.message 
      });
    }
  }

  async listProjects(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { error, value } = queryProjectsSchema.validate(request.query);
      if (error) {
        return reply.status(400).send({ 
          error: 'Validation error', 
          details: error.details 
        });
      }

      const projects = await projectService.listProjects(value);
      return reply.send(projects);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Failed to list projects',
        message: error.message 
      });
    }
  }

  async getStatistics(request: FastifyRequest, reply: FastifyReply) {
    try {
      const stats = await projectService.getProjectStatistics();
      return reply.send(stats);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Failed to get statistics',
        message: error.message 
      });
    }
  }
}

export const projectController = new ProjectController();
CONTROLLER

# Create routes
echo -e "${GREEN}Creating project routes...${NC}"
cat > src/routes/projectRoutes.ts << 'ROUTES'
import { FastifyPluginAsync } from 'fastify';
import { projectController } from '../controllers/projectController';

export const projectRoutes: FastifyPluginAsync = async (fastify) => {
  // Create project
  fastify.post('/', {
    schema: {
      description: 'Create a new project',
      tags: ['projects'],
      body: {
        type: 'object',
        required: ['name'],
        properties: {
          name: { type: 'string' },
          description: { type: 'string' },
          status: { type: 'string' },
          priority: { type: 'string' },
          budget: { type: 'number' },
          startDate: { type: 'string', format: 'date' },
          endDate: { type: 'string', format: 'date' },
          location: { type: 'string' },
          gpsLatitude: { type: 'number' },
          gpsLongitude: { type: 'number' }
        }
      }
    }
  }, (request, reply) => projectController.createProject(request, reply));

  // Get project by ID
  fastify.get('/:id', {
    schema: {
      description: 'Get project by ID',
      tags: ['projects'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => projectController.getProject(request, reply));

  // Update project
  fastify.put('/:id', {
    schema: {
      description: 'Update project',
      tags: ['projects'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => projectController.updateProject(request, reply));

  // Delete project
  fastify.delete('/:id', {
    schema: {
      description: 'Delete project',
      tags: ['projects'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => projectController.deleteProject(request, reply));

  // List projects
  fastify.get('/', {
    schema: {
      description: 'List projects with filtering and pagination',
      tags: ['projects'],
      querystring: {
        type: 'object',
        properties: {
          page: { type: 'number' },
          limit: { type: 'number' },
          status: { type: 'string' },
          priority: { type: 'string' },
          search: { type: 'string' },
          sortBy: { type: 'string' },
          sortOrder: { type: 'string' }
        }
      }
    }
  }, (request, reply) => projectController.listProjects(request, reply));

  // Get statistics
  fastify.get('/stats/overview', {
    schema: {
      description: 'Get project statistics',
      tags: ['projects']
    }
  }, (request, reply) => projectController.getStatistics(request, reply));
};
ROUTES

# Create server
echo -e "${GREEN}Creating server...${NC}"
cat > src/server.ts << 'SERVER'
import fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { projectRoutes } from './routes/projectRoutes';
import dotenv from 'dotenv';

dotenv.config();

const server = fastify({
  logger: {
    prettyPrint: true,
    level: 'info'
  }
});

async function start() {
  try {
    // Register plugins
    await server.register(cors, {
      origin: true,
      credentials: true
    });

    await server.register(jwt, {
      secret: process.env.JWT_SECRET || 'your-secret-key'
    });

    // Health check
    server.get('/health', async () => {
      return { 
        status: 'ok', 
        service: 'project-service',
        timestamp: new Date().toISOString() 
      };
    });

    // Register routes
    await server.register(projectRoutes, { prefix: '/api/v1/projects' });

    // Start server
    const port = parseInt(process.env.PORT || '8081');
    await server.listen({ port, host: '0.0.0.0' });
    
    console.log(`🚀 Project Service running at http://localhost:${port}`);
    console.log(`📚 Health check at http://localhost:${port}/health`);
    console.log(`📋 Projects API at http://localhost:${port}/api/v1/projects`);
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
SERVER

# Generate Prisma client and push schema
echo -e "${GREEN}Setting up database...${NC}"
npx prisma generate
npx prisma db push

# Create test script
echo -e "${GREEN}Creating test script...${NC}"
cat > test-projects.sh << 'TEST'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

API_URL="http://localhost:8081/api/v1/projects"

echo -e "${BLUE}Testing Project Management API${NC}"
echo ""

# Test 1: Create project
echo -e "${YELLOW}1. Creating project...${NC}"
RESPONSE=$(curl -s -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Engineering Project",
    "description": "Test project with GPS coordinates",
    "status": "PLANNING",
    "priority": "HIGH",
    "budget": 1000000,
    "startDate": "2025-01-01",
    "endDate": "2025-12-31",
    "location": "San Francisco, CA",
    "gpsLatitude": 37.7749,
    "gpsLongitude": -122.4194,
    "projectManager": "John Doe",
    "teamMembers": ["Alice", "Bob", "Charlie"],
    "tags": ["engineering", "infrastructure"]
  }')

if echo "$RESPONSE" | grep -q "projectId"; then
  echo -e "${GREEN}✅ Project created successfully${NC}"
  echo "$RESPONSE" | jq .
  PROJECT_ID=$(echo "$RESPONSE" | jq -r .id)
else
  echo -e "${RED}❌ Failed to create project${NC}"
  echo "$RESPONSE"
  exit 1
fi

echo ""

# Test 2: Get project
echo -e "${YELLOW}2. Getting project...${NC}"
curl -s $API_URL/$PROJECT_ID | jq .

echo ""

# Test 3: List projects
echo -e "${YELLOW}3. Listing projects...${NC}"
curl -s "$API_URL?limit=10&status=PLANNING" | jq .

echo ""

# Test 4: Get statistics
echo -e "${YELLOW}4. Getting statistics...${NC}"
curl -s $API_URL/stats/overview | jq .

echo ""
echo -e "${GREEN}All tests completed!${NC}"
TEST
chmod +x test-projects.sh

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Project Service Setup Complete!            ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}To start the project service:${NC}"
echo "  ${BLUE}npm run dev${NC}"
echo ""
echo -e "${YELLOW}To test the API:${NC}"
echo "  ${BLUE}./test-projects.sh${NC}"
echo ""
echo -e "${GREEN}API Endpoints:${NC}"
echo "  POST   /api/v1/projects     - Create project"
echo "  GET    /api/v1/projects     - List projects"
echo "  GET    /api/v1/projects/:id - Get project"
echo "  PUT    /api/v1/projects/:id - Update project"
echo "  DELETE /api/v1/projects/:id - Delete project"
echo "  GET    /api/v1/projects/stats/overview - Statistics"

cd ../../..

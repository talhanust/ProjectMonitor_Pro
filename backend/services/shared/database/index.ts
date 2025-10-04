export { prisma, connectDatabase, disconnectDatabase, checkDatabaseHealth } from './connection';

export { PrismaClient } from '@prisma/client';
export type { User, Project, Task, Comment } from '@prisma/client';

// Re-export all Prisma types
export * from '@prisma/client';

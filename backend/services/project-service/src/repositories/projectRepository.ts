import { PrismaClient, Prisma } from '@prisma/client';
import { CreateProjectDTO, UpdateProjectDTO } from '../models/project.model';

const prisma = new PrismaClient();

export class ProjectRepository {
  async create(data: CreateProjectDTO & { projectId: string; createdBy?: string }) {
    return await prisma.project.create({
      data: {
        ...data,
        startDate: data.startDate ? new Date(data.startDate) : undefined,
        endDate: data.endDate ? new Date(data.endDate) : undefined,
      },
    });
  }

  async findById(id: string) {
    return await prisma.project.findUnique({
      where: { id },
    });
  }

  async findByProjectId(projectId: string) {
    return await prisma.project.findUnique({
      where: { projectId },
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
      },
    });
  }

  async delete(id: string) {
    return await prisma.project.delete({
      where: { id },
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
        orderBy: { [sortBy]: sortOrder },
      }),
      prisma.project.count({ where }),
    ]);

    return {
      projects,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getStatistics() {
    const [total, byStatus, byPriority] = await Promise.all([
      prisma.project.count(),
      prisma.project.groupBy({
        by: ['status'],
        _count: true,
      }),
      prisma.project.groupBy({
        by: ['priority'],
        _count: true,
      }),
    ]);

    return {
      total,
      byStatus,
      byPriority,
    };
  }
}

export const projectRepository = new ProjectRepository();

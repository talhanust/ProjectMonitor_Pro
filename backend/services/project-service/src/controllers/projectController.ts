import { FastifyRequest, FastifyReply } from 'fastify';
import { projectService } from '../services/projectService';
import {
  createProjectSchema,
  updateProjectSchema,
  queryProjectsSchema,
} from '../validators/projectValidator';

export class ProjectController {
  async createProject(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { error, value } = createProjectSchema.validate(request.body);
      if (error) {
        return reply.status(400).send({
          error: 'Validation error',
          details: error.details,
        });
      }

      const userId = (request as any).user?.id;
      const project = await projectService.createProject(value, userId);

      return reply.status(201).send(project);
    } catch (error: any) {
      return reply.status(500).send({
        error: 'Failed to create project',
        message: error.message,
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
        message: error.message,
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
          details: error.details,
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
        message: error.message,
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
        message: error.message,
      });
    }
  }

  async listProjects(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { error, value } = queryProjectsSchema.validate(request.query);
      if (error) {
        return reply.status(400).send({
          error: 'Validation error',
          details: error.details,
        });
      }

      const projects = await projectService.listProjects(value);
      return reply.send(projects);
    } catch (error: any) {
      return reply.status(500).send({
        error: 'Failed to list projects',
        message: error.message,
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
        message: error.message,
      });
    }
  }
}

export const projectController = new ProjectController();

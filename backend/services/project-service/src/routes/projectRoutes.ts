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

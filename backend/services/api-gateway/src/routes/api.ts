import { FastifyPluginAsync } from 'fastify'
import { authenticate, authorizeRoles } from '../middleware/auth'
import { validateRequest, schemas } from '../middleware/validation'

export const apiRoutes: FastifyPluginAsync = async (fastify) => {
  // Public endpoint
  fastify.get('/status', {
    schema: {
      description: 'Get API status',
      tags: ['api'],
      response: {
        200: {
          type: 'object',
          properties: {
            message: { type: 'string' },
            version: { type: 'string' },
            timestamp: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    return {
      message: 'API Gateway is running',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
    }
  })

  // Protected endpoint - Fixed preHandler
  fastify.get('/profile', {
    preHandler: authenticate,
    schema: {
      description: 'Get user profile',
      tags: ['api'],
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            user: { 
              type: 'object',
              properties: {
                id: { type: 'string' },
                email: { type: 'string' },
                role: { type: 'string' },
              },
            },
          },
        },
      },
    },
  }, async (request, reply) => {
    return {
      user: request.user,
    }
  })

  // Admin only endpoint - Fixed preHandler
  fastify.get('/admin', {
    preHandler: authorizeRoles('admin'),
    schema: {
      description: 'Admin only endpoint',
      tags: ['api'],
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            message: { type: 'string' },
            user: { type: 'object' },
          },
        },
      },
    },
  }, async (request, reply) => {
    return {
      message: 'Admin access granted',
      user: request.user,
    }
  })

  // Example CRUD endpoint with validation
  fastify.get('/items', {
    preHandler: async (request, reply) => {
      await validateRequest({ query: schemas.pagination })(request, reply)
    },
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
      response: {
        200: {
          type: 'object',
          properties: {
            items: { type: 'array', items: { type: 'object' } },
            pagination: {
              type: 'object',
              properties: {
                page: { type: 'number' },
                limit: { type: 'number' },
                total: { type: 'number' },
                totalPages: { type: 'number' },
              },
            },
          },
        },
      },
    },
  }, async (request, reply) => {
    const { page = 1, limit = 10, sortBy, sortOrder } = request.query as any
    
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

  // Example POST endpoint with body validation
  fastify.post('/items', {
    preHandler: authenticate,
    schema: {
      description: 'Create a new item',
      tags: ['api'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        required: ['name', 'description'],
        properties: {
          name: { type: 'string', minLength: 1, maxLength: 100 },
          description: { type: 'string', minLength: 1, maxLength: 500 },
        },
      },
      response: {
        201: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            description: { type: 'string' },
            createdAt: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    const { name, description } = request.body as any
    
    reply.status(201)
    return {
      id: 'item-' + Date.now(),
      name,
      description,
      createdAt: new Date().toISOString(),
    }
  })
}

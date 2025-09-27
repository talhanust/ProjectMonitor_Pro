import { FastifyPluginAsync } from 'fastify'
import { authenticate } from '../middleware/auth'

export const userRoutes: FastifyPluginAsync = async (fastify) => {
  // Get current user profile
  fastify.get('/me', {
    preHandler: authenticate,
    schema: {
      description: 'Get current user profile',
      tags: ['users'],
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            email: { type: 'string' },
            name: { type: 'string' },
            role: { type: 'string' },
            createdAt: { type: 'string' },
            updatedAt: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    // In a real app, you would fetch the full user data from database
    // For now, we'll return the user data from the JWT token with mock timestamps
    const user = request.user as any
    
    return {
      id: user.id,
      email: user.email,
      name: user.name || 'User',
      role: user.role,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    }
  })

  // Update current user profile
  fastify.patch('/me', {
    preHandler: authenticate,
    schema: {
      description: 'Update current user profile',
      tags: ['users'],
      security: [{ bearerAuth: [] }],
      body: {
        type: 'object',
        properties: {
          name: { type: 'string', minLength: 2, maxLength: 100 },
          email: { type: 'string', format: 'email' },
        },
      },
      response: {
        200: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            email: { type: 'string' },
            name: { type: 'string' },
            role: { type: 'string' },
            updatedAt: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    const { name, email } = request.body as any
    const user = request.user as any
    
    // In a real app, you would update the user in the database
    return {
      id: user.id,
      email: email || user.email,
      name: name || user.name,
      role: user.role,
      updatedAt: new Date().toISOString(),
    }
  })

  // Delete current user account
  fastify.delete('/me', {
    preHandler: authenticate,
    schema: {
      description: 'Delete current user account',
      tags: ['users'],
      security: [{ bearerAuth: [] }],
      response: {
        200: {
          type: 'object',
          properties: {
            message: { type: 'string' },
          },
        },
      },
    },
  }, async (request, reply) => {
    // In a real app, you would delete the user from database
    return {
      message: 'Account deleted successfully',
    }
  })
}

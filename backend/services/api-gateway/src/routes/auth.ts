import { FastifyPluginAsync } from 'fastify'
import { authController } from '../controllers/authController'
import { authenticate } from '../middleware/auth'
import { validateRequest, schemas } from '../middleware/validation'
import { z } from 'zod'

const loginSchema = z.object({
  email: schemas.email,
  password: z.string().min(6),
})

const registerSchema = z.object({
  email: schemas.email,
  password: schemas.password,
  name: z.string().min(2).max(100),
})

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  // Public routes
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
          name: { type: 'string', minLength: 2, maxLength: 100 },
        },
      },
    },
  }, (request, reply) => authController.register(request, reply))

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
          password: { type: 'string', minLength: 6 },
        },
      },
    },
  }, (request, reply) => authController.login(request, reply))

  fastify.post('/logout', {
    schema: {
      description: 'Logout user',
      tags: ['auth'],
    },
  }, (request, reply) => authController.logout(request, reply))

  fastify.post('/refresh', {
    schema: {
      description: 'Refresh access token',
      tags: ['auth'],
      body: {
        type: 'object',
        required: ['refreshToken'],
        properties: {
          refreshToken: { type: 'string' },
        },
      },
    },
  }, (request, reply) => authController.refreshToken(request, reply))

  // Protected routes
  fastify.get('/me', {
    preHandler: authenticate,
    schema: {
      description: 'Get current user',
      tags: ['auth'],
      security: [{ bearerAuth: [] }],
    },
  }, (request, reply) => authController.getCurrentUser(request, reply))
}

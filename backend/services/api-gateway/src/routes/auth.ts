import { FastifyPluginAsync } from 'fastify'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { validateRequest, schemas } from '../middleware/validation'
import { UnauthorizedError, ConflictError } from '../middleware/errorHandler'

const loginSchema = z.object({
  email: schemas.email,
  password: z.string(),
})

const registerSchema = z.object({
  email: schemas.email,
  password: schemas.password,
  name: z.string().min(2).max(100),
})

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  // Register
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
          name: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password, name } = request.body as z.infer<typeof registerSchema>
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10)
    
    // In a real app, save user to database here
    const userId = 'user-' + Date.now()
    
    // Generate token with name included
    const token = await reply.jwtSign({ 
      id: userId, 
      email, 
      name,
      role: 'user' 
    })
    
    return {
      token,
      user: { id: userId, email, name, role: 'user' },
    }
  })

  // Login
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
          password: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password } = request.body as z.infer<typeof loginSchema>
    
    // In a real app, verify credentials against database
    // For demo, we'll accept any valid email/password
    
    // Mock user data
    const userId = 'user-' + Date.now()
    const name = email.split('@')[0].charAt(0).toUpperCase() + email.split('@')[0].slice(1)
    
    // Generate token with name
    const token = await reply.jwtSign({ 
      id: userId, 
      email, 
      name,
      role: 'user' 
    })
    
    return {
      token,
      user: { id: userId, email, name, role: 'user' },
    }
  })

  // Refresh token
  fastify.post('/refresh', {
    preHandler: validateRequest({ 
      headers: z.object({
        authorization: z.string().startsWith('Bearer '),
      })
    }),
    schema: {
      description: 'Refresh authentication token',
      tags: ['auth'],
      security: [{ bearerAuth: [] }],
    },
  }, async (request, reply) => {
    try {
      await request.jwtVerify()
      const user = request.user as any
      
      // Generate new token
      const token = await reply.jwtSign({
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      })
      
      return { token }
    } catch (err) {
      throw new UnauthorizedError('Invalid token')
    }
  })
}

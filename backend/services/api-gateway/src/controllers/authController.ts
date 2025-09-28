import { FastifyRequest, FastifyReply } from 'fastify'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { UnauthorizedError, ConflictError, ValidationError } from '../middleware/errorHandler'

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
})

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8).regex(
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
    'Password must contain uppercase, lowercase, and number'
  ),
  name: z.string().min(2).max(100),
})

export class AuthController {
  // Simplified register without Supabase for now
  async register(request: FastifyRequest, reply: FastifyReply) {
    const body = registerSchema.parse(request.body)
    
    try {
      // Hash password
      const hashedPassword = await bcrypt.hash(body.password, 10)
      
      // For now, just return mock data
      // In production, save to database
      const userId = 'user-' + Date.now()
      
      // Generate token
      const token = await reply.jwtSign({
        id: userId,
        email: body.email,
        name: body.name,
        role: 'USER',
      })
      
      return {
        user: {
          id: userId,
          email: body.email,
          name: body.name,
          role: 'USER',
        },
        accessToken: token,
        refreshToken: token, // In production, generate separate refresh token
      }
    } catch (error: any) {
      throw new ValidationError(error.message || 'Registration failed')
    }
  }
  
  // Simplified login
  async login(request: FastifyRequest, reply: FastifyReply) {
    const body = loginSchema.parse(request.body)
    
    try {
      // For demo purposes, accept any valid email/password
      // In production, verify against database
      
      const userId = 'user-' + Date.now()
      const name = body.email.split('@')[0].charAt(0).toUpperCase() + body.email.split('@')[0].slice(1)
      
      // Generate token
      const token = await reply.jwtSign({
        id: userId,
        email: body.email,
        name,
        role: 'USER',
      })
      
      return {
        user: {
          id: userId,
          email: body.email,
          name,
          role: 'USER',
        },
        accessToken: token,
        refreshToken: token,
      }
    } catch (error: any) {
      throw new UnauthorizedError(error.message || 'Login failed')
    }
  }
  
  // Logout
  async logout(request: FastifyRequest, reply: FastifyReply) {
    // In production, invalidate token in database/cache
    return { message: 'Logged out successfully' }
  }
  
  // Refresh token - FIXED VERSION
  async refreshToken(request: FastifyRequest, reply: FastifyReply) {
    const { refreshToken } = request.body as { refreshToken: string }
    
    if (!refreshToken) {
      throw new UnauthorizedError('Refresh token required')
    }
    
    try {
      // Verify the refresh token from the body, not from header
      const decoded = await request.server.jwt.verify(refreshToken)
      
      // Generate new access token
      const token = await reply.jwtSign({
        id: (decoded as any).id,
        email: (decoded as any).email,
        name: (decoded as any).name,
        role: (decoded as any).role,
      })
      
      return { accessToken: token }
    } catch (error) {
      throw new UnauthorizedError('Invalid refresh token')
    }
  }
  
  // Get current user
  async getCurrentUser(request: FastifyRequest, reply: FastifyReply) {
    const user = request.user as any
    
    if (!user) {
      throw new UnauthorizedError('Not authenticated')
    }
    
    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      createdAt: new Date().toISOString(),
    }
  }
}

export const authController = new AuthController()
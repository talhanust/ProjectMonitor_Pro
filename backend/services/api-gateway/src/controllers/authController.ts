import { FastifyRequest, FastifyReply } from 'fastify'
import { z } from 'zod'
import bcrypt from 'bcryptjs'
import { PrismaClient } from '@prisma/client'
import { UnauthorizedError, ConflictError, ValidationError } from '../middleware/errorHandler'

const prisma = new PrismaClient()

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
  async register(request: FastifyRequest, reply: FastifyReply) {
    const body = registerSchema.parse(request.body)
    
    try {
      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email: body.email }
      })
      
      if (existingUser) {
        throw new ConflictError('User already exists')
      }
      
      // Hash password
      const hashedPassword = await bcrypt.hash(body.password, 10)
      
      // Create user in database
      const user = await prisma.user.create({
        data: {
          email: body.email,
          password: hashedPassword,
          name: body.name,
          role: 'USER',
        },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
        }
      })
      
      // Generate tokens
      const accessToken = await reply.jwtSign({
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      })
      
      const refreshToken = await reply.jwtSign(
        {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
        { expiresIn: '7d' }
      )
      
      return {
        user,
        accessToken,
        refreshToken,
      }
    } catch (error: any) {
      if (error instanceof ConflictError) throw error
      throw new ValidationError(error.message || 'Registration failed')
    }
  }
  
  async login(request: FastifyRequest, reply: FastifyReply) {
    const body = loginSchema.parse(request.body)
    
    try {
      // Find user in database
      const user = await prisma.user.findUnique({
        where: { email: body.email },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          password: true,
        }
      })
      
      if (!user) {
        throw new UnauthorizedError('Invalid credentials')
      }
      
      // Verify password
      const validPassword = await bcrypt.compare(body.password, user.password)
      
      if (!validPassword) {
        throw new UnauthorizedError('Invalid credentials')
      }
      
      // Remove password from response
      const { password, ...userWithoutPassword } = user
      
      // Generate tokens
      const accessToken = await reply.jwtSign({
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      })
      
      const refreshToken = await reply.jwtSign(
        {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
        },
        { expiresIn: '7d' }
      )
      
      return {
        user: userWithoutPassword,
        accessToken,
        refreshToken,
      }
    } catch (error: any) {
      if (error instanceof UnauthorizedError) throw error
      throw new UnauthorizedError('Login failed')
    }
  }
  
  async logout(request: FastifyRequest, reply: FastifyReply) {
    // In production, you might want to blacklist the token
    // For now, just return success
    return { message: 'Logged out successfully' }
  }
  
  async refreshToken(request: FastifyRequest, reply: FastifyReply) {
    const { refreshToken } = request.body as { refreshToken: string }
    
    if (!refreshToken) {
      throw new UnauthorizedError('Refresh token required')
    }
    
    try {
      // Verify the refresh token
      const decoded = await request.jwtVerify()
      
      // Generate new access token
      const accessToken = await reply.jwtSign({
        id: (decoded as any).id,
        email: (decoded as any).email,
        name: (decoded as any).name,
        role: (decoded as any).role,
      })
      
      return { accessToken }
    } catch (error) {
      throw new UnauthorizedError('Invalid refresh token')
    }
  }
  
  async getCurrentUser(request: FastifyRequest, reply: FastifyReply) {
    const user = request.user as any
    
    if (!user) {
      throw new UnauthorizedError('Not authenticated')
    }
    
    // Fetch fresh user data from database
    const userData = await prisma.user.findUnique({
      where: { id: user.id },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
        updatedAt: true,
      }
    })
    
    if (!userData) {
      throw new UnauthorizedError('User not found')
    }
    
    return userData
  }
}

export const authController = new AuthController()

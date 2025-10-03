#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Adding Prisma to Auth Controller           ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

cd backend/services/api-gateway

echo -e "${GREEN}Updating authController with Prisma...${NC}"
cat > src/controllers/authController.ts << 'AUTHCONTROLLER'
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
AUTHCONTROLLER

echo -e "${GREEN}Checking if Prisma schema exists...${NC}"
if [ ! -f "prisma/schema.prisma" ]; then
  echo -e "${YELLOW}Creating Prisma schema...${NC}"
  mkdir -p prisma
  cat > prisma/schema.prisma << 'PRISMASCHEMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String
  name      String?
  role      String   @default("USER")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@map("users")
}
PRISMASCHEMA
fi

echo -e "${GREEN}Generating Prisma Client...${NC}"
npx prisma generate

echo -e "${GREEN}Checking database connection...${NC}"
if npx prisma db push --skip-generate 2>/dev/null; then
  echo -e "${GREEN}✅ Database schema synchronized${NC}"
else
  echo -e "${YELLOW}⚠️  Could not sync database. You may need to:${NC}"
  echo "  1. Check your DATABASE_URL in .env"
  echo "  2. Run: npx prisma db push"
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Auth Controller with Prisma Ready!         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}The auth controller now includes:${NC}"
echo "  • Full Prisma integration"
echo "  • User persistence in database"
echo "  • Password hashing with bcrypt"
echo "  • Proper error handling"
echo ""
echo -e "${YELLOW}To test:${NC}"
echo "  1. Restart the API Gateway:"
echo "     ${BLUE}npm run dev${NC}"
echo ""
echo "  2. Test registration (creates user in DB):"
echo "     ${BLUE}curl -X POST http://localhost:8080/auth/register \\${NC}"
echo "       ${BLUE}-H 'Content-Type: application/json' \\${NC}"
echo "       ${BLUE}-d '{\"email\":\"test@example.com\",\"password\":\"Test1234\",\"name\":\"Test User\"}'${NC}"
echo ""

cd ../../..

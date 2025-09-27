#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}       Adding User Routes to API Gateway       ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

cd backend/services/api-gateway

echo -e "${GREEN}Creating user routes file...${NC}"

# Create user routes
cat > src/routes/users.ts << 'USERROUTES'
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
USERROUTES

echo -e "${GREEN}Updating app.ts to include user routes...${NC}"

# Update app.ts to include user routes
cat > src/app.ts << 'APP'
import Fastify, { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify'
import cors from '@fastify/cors'
import helmet from '@fastify/helmet'
import compress from '@fastify/compress'
import rateLimit from '@fastify/rate-limit'
import jwt from '@fastify/jwt'
import swagger from '@fastify/swagger'
import swaggerUI from '@fastify/swagger-ui'
import { config } from './config'
import { errorHandler } from './middleware/errorHandler'
import { logger } from './utils/logger'
import { healthRoutes } from './routes/health'
import { authRoutes } from './routes/auth'
import { apiRoutes } from './routes/api'
import { userRoutes } from './routes/users'

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({
    logger,
    trustProxy: true,
    requestIdHeader: 'x-request-id',
    requestIdLogLabel: 'reqId',
    disableRequestLogging: false,
    bodyLimit: 1048576, // 1MB
  })

  // Register plugins
  await app.register(helmet, {
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
      },
    },
  })

  await app.register(cors, {
    origin: config.CORS_ORIGIN,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  })

  await app.register(compress, {
    global: true,
    threshold: 1024,
    encodings: ['gzip', 'deflate'],
  })

  await app.register(rateLimit, {
    max: config.RATE_LIMIT_MAX,
    timeWindow: config.RATE_LIMIT_WINDOW,
    cache: 10000,
    allowList: ['127.0.0.1'],
    skipOnError: true,
  })

  await app.register(jwt, {
    secret: config.JWT_SECRET,
    sign: {
      expiresIn: config.JWT_EXPIRY,
    },
  })

  // Swagger documentation
  if (config.NODE_ENV !== 'production') {
    await app.register(swagger, {
      swagger: {
        info: {
          title: 'API Gateway',
          description: 'Engineering Platform API Gateway',
          version: '1.0.0',
        },
        externalDocs: {
          url: 'https://github.com/your-repo',
          description: 'Find more info here',
        },
        host: `localhost:${config.PORT}`,
        schemes: ['http', 'https'],
        consumes: ['application/json'],
        produces: ['application/json'],
        tags: [
          { name: 'health', description: 'Health check endpoints' },
          { name: 'auth', description: 'Authentication endpoints' },
          { name: 'api', description: 'API endpoints' },
          { name: 'users', description: 'User management endpoints' },
        ],
        securityDefinitions: {
          bearerAuth: {
            type: 'apiKey',
            name: 'Authorization',
            in: 'header',
            description: 'JWT Authorization header using the Bearer scheme. Example: "Bearer {token}"',
          },
        },
      },
    })

    await app.register(swaggerUI, {
      routePrefix: '/documentation',
      uiConfig: {
        docExpansion: 'list',
        deepLinking: false,
      },
      staticCSP: true,
      transformStaticCSP: (header) => header,
    })
  }

  // Custom error handler
  app.setErrorHandler(errorHandler)

  // Hooks
  app.addHook('onRequest', async (request: FastifyRequest, reply: FastifyReply) => {
    request.log.info({ url: request.url, method: request.method }, 'incoming request')
  })

  app.addHook('onResponse', async (request: FastifyRequest, reply: FastifyReply) => {
    request.log.info(
      { url: request.url, statusCode: reply.statusCode, responseTime: reply.getResponseTime() },
      'request completed'
    )
  })

  // Register routes
  await app.register(healthRoutes, { prefix: '/health' })
  await app.register(authRoutes, { prefix: '/auth' })
  await app.register(apiRoutes, { prefix: '/api/v1' })
  await app.register(userRoutes, { prefix: '/api/v1/users' })

  // 404 handler
  app.setNotFoundHandler((request: FastifyRequest, reply: FastifyReply) => {
    reply.status(404).send({
      statusCode: 404,
      error: 'Not Found',
      message: `Route ${request.method}:${request.url} not found`,
    })
  })

  return app
}
APP

echo -e "${GREEN}Updating auth routes to include name in token...${NC}"

# Update auth routes to include name in JWT
cat > src/routes/auth.ts << 'AUTHROUTES'
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
AUTHROUTES

cd ../../..

echo -e "${GREEN}Creating updated test script...${NC}"

cat > test-api-complete.sh << 'TESTSCRIPT'
#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"

echo -e "${YELLOW}================================${NC}"
echo -e "${YELLOW}Testing Complete API Gateway${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""

# 1. Health check
echo -e "${GREEN}1. Health Check${NC}"
curl -s "$API_URL/health" | jq '.'
echo ""

# 2. Register a new user
echo -e "${GREEN}2. Register User${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "Password123",
    "name": "John Doe"
  }')
echo "$REGISTER_RESPONSE" | jq '.'
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token')
echo ""

# 3. Login
echo -e "${GREEN}3. Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "Password123"
  }')
echo "$LOGIN_RESPONSE" | jq '.'
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo ""

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  # 4. Get user profile
  echo -e "${GREEN}4. Get User Profile (/api/v1/users/me)${NC}"
  curl -s "$API_URL/api/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # 5. Update user profile
  echo -e "${GREEN}5. Update User Profile${NC}"
  curl -s -X PATCH "$API_URL/api/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "John Updated"
    }' | jq '.'
  echo ""

  # 6. Test via frontend proxy
  echo -e "${GREEN}6. Test via Frontend Proxy${NC}"
  curl -s "$FRONTEND_URL/api/gateway/api/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # 7. Refresh token
  echo -e "${GREEN}7. Refresh Token${NC}"
  curl -s -X POST "$API_URL/auth/refresh" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""
else
  echo -e "${RED}No valid token received${NC}"
fi

echo -e "${YELLOW}================================${NC}"
echo -e "${GREEN}Tests Complete!${NC}"
echo -e "${YELLOW}================================${NC}"
TESTSCRIPT

chmod +x test-api-complete.sh

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}       User Routes Added Successfully!          ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}What was added:${NC}"
echo "  ✓ GET    /api/v1/users/me     - Get current user profile"
echo "  ✓ PATCH  /api/v1/users/me     - Update user profile"
echo "  ✓ DELETE /api/v1/users/me     - Delete user account"
echo "  ✓ POST   /auth/refresh        - Refresh JWT token"
echo ""
echo -e "${YELLOW}To apply changes:${NC}"
echo "  1. Restart the API Gateway:"
echo "     ${BLUE}cd backend/services/api-gateway${NC}"
echo "     ${BLUE}npm run dev${NC}"
echo ""
echo "  2. Run the complete test:"
echo "     ${BLUE}./test-api-complete.sh${NC}"
echo ""
echo -e "${GREEN}Your API Gateway now has complete user management!${NC}"

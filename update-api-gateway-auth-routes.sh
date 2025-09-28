#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Updating API Gateway Auth Routes           ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

cd backend/services/api-gateway

echo -e "${GREEN}Creating updated auth routes...${NC}"
cat > src/routes/auth.ts << 'AUTHROUTES'
import { FastifyPluginAsync } from 'fastify'
import { authController } from '../controllers/authController'
import { authenticate } from '../middleware/auth'

export const authRoutes: FastifyPluginAsync = async (fastify) => {
  // Public routes
  fastify.post('/register', {
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
  }, authController.register)

  fastify.post('/login', {
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
  }, authController.login)

  fastify.post('/logout', {
    schema: {
      description: 'Logout user',
      tags: ['auth'],
    },
  }, authController.logout)

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
  }, authController.refreshToken)

  // Protected routes
  fastify.get('/me', {
    preHandler: authenticate,
    schema: {
      description: 'Get current user',
      tags: ['auth'],
      security: [{ bearerAuth: [] }],
    },
  }, authController.getCurrentUser)
}
AUTHROUTES

echo -e "${GREEN}Authentication routes updated!${NC}"
echo ""
echo "Restart your API Gateway to apply changes:"
echo "  ${BLUE}npm run dev${NC}"

cd ../../..

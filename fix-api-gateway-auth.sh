#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}       Fixing API Gateway Auth Issues          ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Navigate to API Gateway directory
cd backend/services/api-gateway

echo -e "${GREEN}Fixing authentication middleware...${NC}"

# Fix the auth middleware
cat > src/middleware/auth.ts << 'AUTH'
import { FastifyRequest, FastifyReply } from 'fastify'
import { config } from '../config'

export interface User {
  id: string
  email: string
  role: string
}

declare module 'fastify' {
  interface FastifyRequest {
    user?: User
  }
}

export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify()
    // The JWT token is valid and the user info is available in request.user
  } catch (err) {
    reply.status(401).send({ error: 'Unauthorized', message: 'Invalid or missing token' })
  }
}

// Fixed: This now returns a function directly, not a function that returns a function
export function authorizeRoles(...roles: string[]) {
  return async function(request: FastifyRequest, reply: FastifyReply) {
    try {
      await request.jwtVerify()
      
      if (!request.user) {
        return reply.status(401).send({ error: 'Unauthorized' })
      }

      const userRole = (request.user as any).role
      
      if (!roles.includes(userRole)) {
        return reply.status(403).send({ 
          error: 'Forbidden', 
          message: 'Insufficient permissions' 
        })
      }
    } catch (err) {
      return reply.status(401).send({ error: 'Unauthorized', message: 'Invalid or missing token' })
    }
  }
}

export async function optionalAuth(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify()
  } catch (err) {
    // Token is invalid or missing, but we continue anyway
    request.user = undefined
  }
}
AUTH

echo -e "${GREEN}Fixing API routes...${NC}"

# Fix the API routes
cat > src/routes/api.ts << 'APIROUTES'
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
APIROUTES

echo -e "${GREEN}Creating test script for API endpoints...${NC}"

cd ../../..

cat > test-api-gateway.sh << 'TESTSCRIPT'
#!/bin/bash

API_URL="http://localhost:8080"
EMAIL="test@example.com"
PASSWORD="Test1234"
NAME="Test User"

echo "================================"
echo "Testing API Gateway Endpoints"
echo "================================"
echo ""

# Health check
echo "1. Testing health endpoint..."
curl -s "$API_URL/health" | jq '.'
echo ""

# API Status
echo "2. Testing API status..."
curl -s "$API_URL/api/v1/status" | jq '.'
echo ""

# Register
echo "3. Testing registration..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"name\":\"$NAME\"}")
echo "$REGISTER_RESPONSE" | jq '.'
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token')
echo ""

# Login
echo "4. Testing login..."
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
echo "$LOGIN_RESPONSE" | jq '.'
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo ""

if [ "$TOKEN" != "null" ] && [ -n "$TOKEN" ]; then
  # Protected endpoint
  echo "5. Testing protected profile endpoint..."
  curl -s "$API_URL/api/v1/profile" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # Admin endpoint (will fail with user role)
  echo "6. Testing admin endpoint (should fail with user role)..."
  curl -s "$API_URL/api/v1/admin" \
    -H "Authorization: Bearer $TOKEN" | jq '.'
  echo ""

  # Create item
  echo "7. Testing create item..."
  curl -s -X POST "$API_URL/api/v1/items" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Item","description":"This is a test item"}' | jq '.'
  echo ""
else
  echo "No token received, skipping authenticated endpoints"
fi

# Paginated items
echo "8. Testing paginated items..."
curl -s "$API_URL/api/v1/items?page=1&limit=5" | jq '.'
echo ""

echo "================================"
echo "Tests completed!"
echo "================================"
TESTSCRIPT

chmod +x test-api-gateway.sh

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}          Auth Issues Fixed!                   ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}What was fixed:${NC}"
echo "  ✓ authorizeRoles now returns a function directly"
echo "  ✓ validateRequest preHandler properly wrapped"
echo "  ✓ All route handlers properly configured"
echo "  ✓ Added response schemas for better documentation"
echo ""
echo -e "${YELLOW}To restart the API Gateway:${NC}"
echo "  1. Stop the current process (Ctrl+C)"
echo "  2. Start it again:"
echo "     ${BLUE}cd backend/services/api-gateway${NC}"
echo "     ${BLUE}npm run dev${NC}"
echo ""
echo -e "${YELLOW}To test all endpoints:${NC}"
echo "     ${BLUE}./test-api-gateway.sh${NC}"
echo ""
echo -e "${YELLOW}API Documentation:${NC}"
echo "     ${BLUE}http://localhost:8080/documentation${NC}"
echo ""
echo -e "${GREEN}Your API Gateway should now start without errors!${NC}"

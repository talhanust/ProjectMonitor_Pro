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

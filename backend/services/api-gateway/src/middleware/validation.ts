import { FastifyRequest, FastifyReply } from 'fastify'
import { z, ZodSchema } from 'zod'
import { ValidationError } from './errorHandler'

interface ValidationSchemas {
  body?: ZodSchema
  query?: ZodSchema
  params?: ZodSchema
  headers?: ZodSchema
}

export function validateRequest(schemas: ValidationSchemas) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    try {
      // Validate body
      if (schemas.body && request.body) {
        request.body = schemas.body.parse(request.body)
      }

      // Validate query
      if (schemas.query && request.query) {
        request.query = schemas.query.parse(request.query)
      }

      // Validate params
      if (schemas.params && request.params) {
        request.params = schemas.params.parse(request.params)
      }

      // Validate headers
      if (schemas.headers && request.headers) {
        schemas.headers.parse(request.headers)
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        throw new ValidationError('Validation failed', error.errors)
      }
      throw error
    }
  }
}

// Common validation schemas
export const schemas = {
  // ID validation
  id: z.string().uuid(),
  
  // Pagination
  pagination: z.object({
    page: z.string().optional().transform((val) => parseInt(val || '1', 10)),
    limit: z.string().optional().transform((val) => parseInt(val || '10', 10)),
    sortBy: z.string().optional(),
    sortOrder: z.enum(['asc', 'desc']).optional(),
  }),
  
  // Email
  email: z.string().email(),
  
  // Password (min 8 chars, 1 uppercase, 1 lowercase, 1 number)
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number'),
}

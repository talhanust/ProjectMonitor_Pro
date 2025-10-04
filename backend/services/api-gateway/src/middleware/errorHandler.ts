import { FastifyError, FastifyRequest, FastifyReply } from 'fastify';
import { ZodError } from 'zod';
import { config } from '../config';

export interface ApiError extends Error {
  statusCode?: number;
  validation?: any;
}

export async function errorHandler(
  error: FastifyError | ApiError | ZodError,
  request: FastifyRequest,
  reply: FastifyReply,
) {
  // Log the error
  request.log.error(error);

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    return reply.status(400).send({
      statusCode: 400,
      error: 'Validation Error',
      message: 'Invalid request data',
      validation: error.errors,
    });
  }

  // Handle JWT errors
  if (error.message === 'No Authorization was found in request.headers') {
    return reply.status(401).send({
      statusCode: 401,
      error: 'Unauthorized',
      message: 'Missing authentication token',
    });
  }

  // Handle rate limit errors
  if ((error as any).statusCode === 429) {
    return reply.status(429).send({
      statusCode: 429,
      error: 'Too Many Requests',
      message: 'Rate limit exceeded. Please try again later.',
    });
  }

  // Handle custom API errors
  const statusCode = (error as ApiError).statusCode || 500;
  const message = error.message || 'Internal Server Error';

  // Don't expose internal errors in production
  if (config.NODE_ENV === 'production' && statusCode === 500) {
    return reply.status(500).send({
      statusCode: 500,
      error: 'Internal Server Error',
      message: 'An unexpected error occurred',
    });
  }

  return reply.status(statusCode).send({
    statusCode,
    error: error.name || 'Error',
    message,
    ...(config.NODE_ENV !== 'production' && { stack: error.stack }),
  });
}

export class ValidationError extends Error {
  statusCode = 400;

  constructor(
    message: string,
    public validation?: any,
  ) {
    super(message);
    this.name = 'ValidationError';
  }
}

export class UnauthorizedError extends Error {
  statusCode = 401;

  constructor(message = 'Unauthorized') {
    super(message);
    this.name = 'UnauthorizedError';
  }
}

export class ForbiddenError extends Error {
  statusCode = 403;

  constructor(message = 'Forbidden') {
    super(message);
    this.name = 'ForbiddenError';
  }
}

export class NotFoundError extends Error {
  statusCode = 404;

  constructor(message = 'Not Found') {
    super(message);
    this.name = 'NotFoundError';
  }
}

export class ConflictError extends Error {
  statusCode = 409;

  constructor(message = 'Conflict') {
    super(message);
    this.name = 'ConflictError';
  }
}

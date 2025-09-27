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

import fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import { documentRoutes } from './routes/documentRoutes';
import dotenv from 'dotenv';

dotenv.config();

const server = fastify({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname',
        colorize: true,
      },
    },
  },
});

async function start() {
  try {
    // Register plugins
    await server.register(cors, {
      origin: true,
      credentials: true,
    });

    await server.register(jwt, {
      secret: process.env.JWT_SECRET || 'your-secret-key',
    });

    await server.register(multipart, {
      limits: {
        fileSize: 20 * 1024 * 1024, // 20MB max
        files: 10, // Max 10 files per request
      },
    });

    // Health check
    server.get('/health', async () => {
      return {
        status: 'ok',
        service: 'document-service',
        timestamp: new Date().toISOString(),
      };
    });

    // Register routes
    await server.register(documentRoutes, { prefix: '/api/v1/documents' });

    // Start server
    const port = parseInt(process.env.PORT || '8082');
    await server.listen({ port, host: '0.0.0.0' });

    server.log.info(`🚀 Document Service running at http://localhost:${port}`);
    server.log.info(`📚 Health check at http://localhost:${port}/health`);
    server.log.info(`📁 Documents API at http://localhost:${port}/api/v1/documents`);
  } catch (error) {
    server.log.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();

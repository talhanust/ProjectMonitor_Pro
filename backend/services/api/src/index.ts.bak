import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import { config } from './config/env';
import { logger } from './utils/logger';

const server = Fastify({
  logger,
});

async function bootstrap() {
  try {
    // Register plugins
    await server.register(helmet);
    await server.register(cors, {
      origin: config.CORS_ORIGIN,
      credentials: true,
    });
    await server.register(rateLimit, {
      max: 100,
      timeWindow: '1 minute',
    });

    // Health check route
    server.get('/health', async () => {
      return {
        status: 'ok',
        service: 'backend-api',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
      };
    });

    // API routes
    server.get('/api/v1/status', async () => {
      return {
        message: 'Engineering Platform API',
        version: '1.0.0',
        environment: config.NODE_ENV,
      };
    });

    // Start server
    await server.listen({ port: config.PORT, host: '0.0.0.0' });
    console.log(`Server running at http://localhost:${config.PORT}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

bootstrap();

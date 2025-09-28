import fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import { projectRoutes } from './routes/projectRoutes';
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
        colorize: true
      }
    }
  }
});

async function start() {
  try {
    // Register plugins
    await server.register(cors, {
      origin: true,
      credentials: true
    });

    await server.register(jwt, {
      secret: process.env.JWT_SECRET || 'your-secret-key'
    });

    // Health check
    server.get('/health', async () => {
      return { 
        status: 'ok', 
        service: 'project-service',
        timestamp: new Date().toISOString() 
      };
    });

    // Register routes
    await server.register(projectRoutes, { prefix: '/api/v1/projects' });

    // Start server
    const port = parseInt(process.env.PORT || '8081');
    await server.listen({ port, host: '0.0.0.0' });
    
    server.log.info(`🚀 Project Service running at http://localhost:${port}`);
    server.log.info(`📚 Health check at http://localhost:${port}/health`);
    server.log.info(`📋 Projects API at http://localhost:${port}/api/v1/projects`);
  } catch (error) {
    server.log.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();

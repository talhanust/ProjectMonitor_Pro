import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './config';
import { setupRoutes } from './routes';

const server = Fastify({
  logger: {
    level: process.env['LOG_LEVEL'] || 'info',
    transport: {
      target: 'pino-pretty',
    },
  },
});

async function start() {
  try {
    await server.register(cors, {
      origin: true,
    });

    setupRoutes(server);

    const port = config.PORT || 8080;
    await server.listen({ port, host: '0.0.0.0' });

    console.log(`Server running at http://localhost:${port}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

start();

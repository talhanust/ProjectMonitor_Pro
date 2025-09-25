import { FastifyInstance } from 'fastify';

let counter = 0;

export function setupRoutes(server: FastifyInstance) {
  server.get('/health', async () => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  server.get('/counter', async () => {
    return { value: counter };
  });

  server.post('/counter/increment', async () => {
    counter++;
    return { value: counter };
  });
}

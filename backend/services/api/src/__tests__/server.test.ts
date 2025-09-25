import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import Fastify from 'fastify';
import { setupRoutes } from '../routes';

describe('Server Routes', () => {
  const fastify = Fastify({ logger: false });

  beforeAll(async () => {
    setupRoutes(fastify);
    await fastify.ready();
  });

  afterAll(async () => {
    await fastify.close();
  });

  it('should return health status', async () => {
    const response = await fastify.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(200);
    const data = JSON.parse(response.payload);
    expect(data.status).toBe('ok');
    expect(data.timestamp).toBeDefined();
  });

  it('should get counter value', async () => {
    const response = await fastify.inject({
      method: 'GET',
      url: '/counter',
    });

    expect(response.statusCode).toBe(200);
    const data = JSON.parse(response.payload);
    expect(data).toHaveProperty('value');
    expect(typeof data.value).toBe('number');
  });

  it('should increment counter', async () => {
    const initialResponse = await fastify.inject({
      method: 'GET',
      url: '/counter',
    });
    const initialValue = JSON.parse(initialResponse.payload).value;

    const incrementResponse = await fastify.inject({
      method: 'POST',
      url: '/counter/increment',
    });

    expect(incrementResponse.statusCode).toBe(200);
    const newValue = JSON.parse(incrementResponse.payload).value;
    expect(newValue).toBe(initialValue + 1);
  });
});

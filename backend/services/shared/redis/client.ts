import Redis from 'ioredis';
import { logger } from '../logger';

class RedisClient {
  private static instance: Redis | null = null;

  static getClient(): Redis {
    if (!this.instance) {
      this.instance = new Redis({
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        password: process.env.REDIS_PASSWORD,
        db: parseInt(process.env.REDIS_DB || '0'),
        maxRetriesPerRequest: null,
        enableReadyCheck: false,
        retryStrategy: (times) => Math.min(times * 50, 2000),
      });

      this.instance.on('connect', () => logger.info('Redis connected'));
      this.instance.on('error', (err) => logger.error('Redis error:', err));
    }
    return this.instance;
  }

  static async disconnect(): Promise<void> {
    if (this.instance) {
      await this.instance.quit();
      this.instance = null;
    }
  }

  static async healthCheck(): Promise<boolean> {
    try {
      return (await this.getClient().ping()) === 'PONG';
    } catch (error) {
      return false;
    }
  }
}

export default RedisClient;

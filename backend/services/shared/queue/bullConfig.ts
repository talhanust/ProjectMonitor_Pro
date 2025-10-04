import Queue, { QueueOptions } from 'bull';
import { logger } from '../logger';

export const createQueue = <T = any>(name: string, options?: Partial<QueueOptions>): Queue<T> => {
  const queue = new Queue<T>(name, {
    redis: {
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD,
      db: parseInt(process.env.REDIS_DB || '0'),
    },
    defaultJobOptions: {
      attempts: 3,
      backoff: { type: 'exponential', delay: 2000 },
      removeOnComplete: { age: 86400, count: 1000 },
      removeOnFail: { age: 604800 },
    },
    limiter: { max: 10, duration: 1000 },
    ...options,
  });

  queue.on('error', (error) => logger.error(`Queue ${name} error:`, error));
  queue.on('completed', (job) => logger.info(`Job ${job.id} completed`));
  queue.on('failed', (job, err) => logger.error(`Job ${job.id} failed:`, err));

  return queue;
};

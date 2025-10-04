import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import mmrRoutes from './routes/mmrRoutes';
import uploadRoutes from './routes/uploadRoutes';
import mmrWorker from './workers/mmrWorker';
import RedisClient from '../../shared/redis/client';
import { logger } from '../../shared/logger';
import { errorHandler } from '../../shared/middleware/errorHandler';

class MMRServiceApp {
  public app: Application;
  private port: number;

  constructor() {
    this.app = express();
    this.port = parseInt(process.env.MMR_SERVICE_PORT || '3001');

    this.initializeMiddlewares();
    this.initializeRoutes();
    this.initializeErrorHandling();
  }

  private initializeMiddlewares(): void {
    this.app.use(helmet());
    this.app.use(cors({ origin: process.env.CORS_ORIGIN || '*', credentials: true }));
    this.app.use(compression());
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true, limit: '10mb' }));
  }

  private initializeRoutes(): void {
    this.app.get('/health', async (req, res) => {
      const redisHealthy = await RedisClient.healthCheck();
      const workerRunning = mmrWorker.isRunning();

      res.status(redisHealthy && workerRunning ? 200 : 503).json({
        status: redisHealthy && workerRunning ? 'healthy' : 'unhealthy',
        timestamp: new Date().toISOString(),
        service: 'mmr-service',
        redis: redisHealthy ? 'connected' : 'disconnected',
        worker: workerRunning ? 'running' : 'stopped',
      });
    });

    // Authenticated upload endpoint
    this.app.use('/api/upload', uploadRoutes);

    // Protected MMR routes (requires auth)
    this.app.use('/api/mmr', mmrRoutes);

    this.app.use((req, res) => {
      res
        .status(404)
        .json({ error: 'Not Found', message: `Route ${req.method} ${req.path} not found` });
    });
  }

  private initializeErrorHandling(): void {
    this.app.use(errorHandler);
  }

  public async start(): Promise<void> {
    try {
      const redisClient = RedisClient.getClient();
      await redisClient.ping();
      logger.info('Redis connection established');

      await mmrWorker.start();
      logger.info('MMR worker started');

      this.app.listen(this.port, '0.0.0.0', () => {
        logger.info(`MMR service listening on port ${this.port}`);
      });
    } catch (error) {
      logger.error('Failed to start MMR service:', error);
      process.exit(1);
    }
  }

  public async stop(): Promise<void> {
    try {
      await mmrWorker.stop();
      await RedisClient.disconnect();
      logger.info('MMR service shutdown complete');
      process.exit(0);
    } catch (error) {
      logger.error('Error during shutdown:', error);
      process.exit(1);
    }
  }
}

const app = new MMRServiceApp();

process.on('SIGTERM', async () => await app.stop());
process.on('SIGINT', async () => await app.stop());

export default app;

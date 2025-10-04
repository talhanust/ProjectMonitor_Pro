#!/bin/bash

# Add Authenticated Upload Endpoint to MMR Service
# Creates an upload endpoint that requires authentication

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     Add Authenticated Upload Endpoint to MMR Service                ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/backend/services/mmr-service

echo -e "${BLUE}[1/4]${NC} Creating uploads directory..."
mkdir -p uploads
echo -e "${GREEN}✓${NC} Directory created"

echo -e "${BLUE}[2/4]${NC} Installing multer for file uploads..."
npm install multer @types/multer
echo -e "${GREEN}✓${NC} Multer installed"

echo -e "${BLUE}[3/4]${NC} Creating authenticated upload route..."
cat > src/routes/uploadRoutes.ts << 'EOF'
import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import fs from 'fs';
import { authMiddleware } from '../../../shared/middleware/auth';

const router = Router();

// Apply authentication to all routes
router.use(authMiddleware);

// Ensure upload directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueName = `${uuidv4()}${path.extname(file.originalname)}`;
    cb(null, uniqueName);
  }
});

const upload = multer({ 
  storage,
  limits: { 
    fileSize: 20 * 1024 * 1024 // 20MB
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['.xlsx', '.xls'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only Excel files are allowed'));
    }
  }
});

// Authenticated upload endpoint
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    res.json({
      success: true,
      message: 'File uploaded successfully',
      data: {
        fileId: path.parse(req.file.filename).name,
        filename: req.file.filename,
        originalname: req.file.originalname,
        path: req.file.path,
        size: req.file.size,
        userId: userId,
        uploadedAt: new Date().toISOString()
      }
    });
  } catch (error: any) {
    res.status(500).json({ 
      success: false,
      error: 'Upload failed', 
      message: error.message 
    });
  }
});

export default router;
EOF

echo -e "${GREEN}✓${NC} Upload routes created with authentication"

echo -e "${BLUE}[4/4]${NC} Updating app.ts to include upload routes..."

cat > src/app.ts << 'EOF'
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
      res.status(404).json({ error: 'Not Found', message: `Route ${req.method} ${req.path} not found` });
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
EOF

echo -e "${GREEN}✓${NC} app.ts updated"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           ✅ Authenticated Upload Endpoint Added!                   ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "The MMR service now has an authenticated upload endpoint:"
echo "  POST /api/upload/upload (requires authentication)"
echo ""
echo "Next steps:"
echo "  1. Restart MMR service"
echo "  2. Update frontend to:"
echo "     - Use endpoint: /api/upload/upload"
echo "     - Send authentication token in headers"
echo ""
echo "To restart MMR service:"
echo "  - Stop current service (Ctrl+C)"
echo "  - Run: npm run dev"
echo ""
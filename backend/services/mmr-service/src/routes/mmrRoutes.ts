import { Router } from 'express';
import mmrController from '../controllers/mmrController';
import { authMiddleware } from '../../../shared/middleware/auth';
import { validateRequest } from '../../../shared/middleware/validation';
import { body, param } from 'express-validator';

const router = Router();
router.use(authMiddleware);

router.post(
  '/process',
  [
    body('fileName').isString().notEmpty(),
    body('filePath').isString().notEmpty(),
    body('fileSize').isInt({ min: 1 }),
    body('uploadId').isString().notEmpty(),
  ],
  validateRequest,
  mmrController.processFile.bind(mmrController),
);

router.post(
  '/process/batch',
  [
    body('files').isArray({ min: 1, max: 10 }),
    body('files.*.fileName').isString().notEmpty(),
    body('files.*.filePath').isString().notEmpty(),
    body('files.*.fileSize').isInt({ min: 1 }),
    body('files.*.uploadId').isString().notEmpty(),
  ],
  validateRequest,
  mmrController.processBatch.bind(mmrController),
);

router.get(
  '/jobs/:jobId',
  [param('jobId').isUUID()],
  validateRequest,
  mmrController.getJobStatus.bind(mmrController),
);

router.get('/jobs', mmrController.getUserJobs.bind(mmrController));

router.post(
  '/jobs/:jobId/cancel',
  [param('jobId').isUUID()],
  validateRequest,
  mmrController.cancelJob.bind(mmrController),
);

router.delete(
  '/jobs/:jobId',
  [param('jobId').isUUID()],
  validateRequest,
  mmrController.deleteJob.bind(mmrController),
);

export default router;

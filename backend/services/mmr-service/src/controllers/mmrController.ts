import { Request, Response, NextFunction } from 'express';
import mmrService from '../services/mmrService';
import { JobStatus } from '../utils/jobTracker';
import { logger } from '../../../shared/logger';

class MMRController {
  async processFile(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });

      const { fileName, filePath, fileSize, uploadId, options } = req.body;
      if (!fileName || !filePath || !fileSize || !uploadId) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      const jobId = await mmrService.processFile({
        userId,
        fileName,
        filePath,
        fileSize,
        uploadId,
        options,
      });
      res.status(202).json({ message: 'File processing started', jobId });
    } catch (error: any) {
      next(error);
    }
  }

  async processBatch(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });

      const { files, options } = req.body;
      if (!files || !Array.isArray(files)) {
        return res.status(400).json({ error: 'Invalid files array' });
      }

      const jobIds = await mmrService.processBatch({ userId, files, options });
      res.status(202).json({ message: 'Batch processing started', jobIds, count: jobIds.length });
    } catch (error: any) {
      next(error);
    }
  }

  async getJobStatus(req: Request, res: Response, next: NextFunction) {
    try {
      const { jobId } = req.params;
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });

      const job = await mmrService.getJobStatus(jobId);
      if (!job) return res.status(404).json({ error: 'Job not found' });
      if (job.userId !== userId) return res.status(403).json({ error: 'Forbidden' });

      res.json(job);
    } catch (error: any) {
      next(error);
    }
  }

  async getUserJobs(req: Request, res: Response, next: NextFunction) {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });

      const limit = parseInt(req.query.limit as string) || 50;
      const offset = parseInt(req.query.offset as string) || 0;
      const status = req.query.status as JobStatus;

      const jobs = status
        ? await mmrService.getJobsByStatus(userId, status)
        : await mmrService.getUserJobs(userId, limit, offset);

      res.json({ jobs, count: jobs.length });
    } catch (error: any) {
      next(error);
    }
  }

  async cancelJob(req: Request, res: Response, next: NextFunction) {
    try {
      const { jobId } = req.params;
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });

      const job = await mmrService.getJobStatus(jobId);
      if (!job) return res.status(404).json({ error: 'Job not found' });
      if (job.userId !== userId) return res.status(403).json({ error: 'Forbidden' });

      await mmrService.cancelJob(jobId);
      res.json({ message: 'Job cancelled', jobId });
    } catch (error: any) {
      next(error);
    }
  }

  async deleteJob(req: Request, res: Response, next: NextFunction) {
    try {
      const { jobId } = req.params;
      const userId = (req as any).user?.id;
      if (!userId) return res.status(401).json({ error: 'Unauthorized' });

      const job = await mmrService.getJobStatus(jobId);
      if (!job) return res.status(404).json({ error: 'Job not found' });
      if (job.userId !== userId) return res.status(403).json({ error: 'Forbidden' });

      await mmrService.deleteJob(jobId);
      res.json({ message: 'Job deleted', jobId });
    } catch (error: any) {
      next(error);
    }
  }
}

export default new MMRController();

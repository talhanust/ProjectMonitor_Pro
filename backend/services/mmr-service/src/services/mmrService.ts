import { v4 as uuidv4 } from 'uuid';
import mmrQueue from '../queues/mmrQueue';
import jobTracker, { JobMetadata, JobStatus } from '../utils/jobTracker';
import { logger } from '../../../shared/logger';
import * as fs from 'fs/promises';
import * as path from 'path';

export interface ProcessFileRequest {
  userId: string;
  fileName: string;
  filePath: string;
  fileSize: number;
  uploadId: string;
  options?: any;
}

class MMRService {
  async processFile(request: ProcessFileRequest): Promise<string> {
    const { userId, fileName, filePath, fileSize, uploadId, options } = request;

    try {
      await fs.access(filePath);
    } catch (error) {
      throw new Error(`File not found: ${filePath}`);
    }

    const maxFileSize = 100 * 1024 * 1024;
    if (fileSize > maxFileSize) {
      throw new Error(`File size exceeds maximum`);
    }

    const allowedExtensions = ['.pdf', '.docx', '.txt', '.png', '.jpg', '.jpeg', '.xlsx', '.xls'];
    const fileExtension = path.extname(fileName).toLowerCase();
    if (!allowedExtensions.includes(fileExtension)) {
      throw new Error(`Unsupported file type: ${fileExtension}`);
    }

    const jobId = uuidv4();
    await jobTracker.createJob(jobId, userId, fileName, fileSize);
    await mmrQueue.addJob({ jobId, userId, fileName, filePath, fileSize, uploadId, options });

    logger.info(`File processing job created: ${jobId}`);
    return jobId;
  }

  async processBatch(request: { userId: string; files: any[]; options?: any }): Promise<string[]> {
    const { userId, files, options } = request;
    if (files.length > 10) throw new Error(`Batch size exceeds maximum of 10`);

    const jobIds: string[] = [];
    const jobDataList: any[] = [];

    for (const file of files) {
      try {
        await fs.access(file.filePath);
        const jobId = uuidv4();
        jobIds.push(jobId);
        await jobTracker.createJob(jobId, userId, file.fileName, file.fileSize);
        jobDataList.push({ jobId, userId, ...file, options });
      } catch (error) {
        logger.warn(`Skipping file: ${file.fileName}`);
      }
    }

    if (jobDataList.length > 0) {
      await mmrQueue.addBatchJobs(jobDataList);
    }

    return jobIds;
  }

  async getJobStatus(jobId: string): Promise<JobMetadata | null> {
    return await jobTracker.getJob(jobId);
  }

  async getUserJobs(userId: string, limit = 50, offset = 0): Promise<JobMetadata[]> {
    return await jobTracker.getUserJobs(userId, limit, offset);
  }

  async getJobsByStatus(userId: string, status: JobStatus): Promise<JobMetadata[]> {
    return await jobTracker.getJobsByStatus(userId, status);
  }

  async cancelJob(jobId: string): Promise<void> {
    await jobTracker.updateJobStatus(jobId, JobStatus.CANCELLED);
  }

  async deleteJob(jobId: string): Promise<void> {
    await mmrQueue.getJob(jobId);
    await jobTracker.deleteJob(jobId);
  }
}

export default new MMRService();

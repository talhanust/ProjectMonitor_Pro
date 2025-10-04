import Queue, { Job } from 'bull';
import { createQueue } from '../../../shared/queue/bullConfig';
import { logger } from '../../../shared/logger';

export interface MMRJobData {
  jobId: string;
  userId: string;
  fileName: string;
  filePath: string;
  fileSize: number;
  uploadId: string;
  options?: {
    extractTables?: boolean;
    extractImages?: boolean;
    detectLanguage?: boolean;
    performOCR?: boolean;
  };
}

export interface MMRJobResult {
  jobId: string;
  uploadId: string;
  extractedText: string;
  metadata: {
    pageCount?: number;
    sheetCount?: number;
    sheetNames?: string[];
    totalRows?: number;
    isMMRDocument?: boolean;
    wordCount: number;
    language?: string;
    processingTime: number;
  };
  tables?: any[];
  images?: any[];
  mmrData?: any[];
  error?: string;
}

class MMRQueue {
  private queue: Queue<MMRJobData>;

  constructor() {
    this.queue = createQueue<MMRJobData>('mmr-processing', {
      settings: {
        maxStalledCount: 3,
        stalledInterval: 30000,
        lockDuration: 300000,
        lockRenewTime: 150000,
      },
    });
  }

  async addJob(data: MMRJobData): Promise<Job<MMRJobData>> {
    const job = await this.queue.add(data, {
      jobId: data.jobId,
      priority: this.calculatePriority(data.fileSize),
      timeout: 600000,
    });
    logger.info(`Job ${job.id} added to queue`);
    return job;
  }

  async addBatchJobs(jobs: MMRJobData[]): Promise<Job<MMRJobData>[]> {
    const batchJobs = jobs.map((data) => ({
      name: 'mmr-process',
      data,
      opts: { jobId: data.jobId, priority: this.calculatePriority(data.fileSize) },
    }));
    return await this.queue.addBulk(batchJobs);
  }

  private calculatePriority(fileSize: number): number {
    const MB = 1024 * 1024;
    if (fileSize < MB) return 1;
    if (fileSize < 5 * MB) return 2;
    if (fileSize < 10 * MB) return 3;
    return 4;
  }

  async getJob(jobId: string): Promise<Job<MMRJobData> | null> {
    return await this.queue.getJob(jobId);
  }

  getQueue() {
    return this.queue;
  }

  async close(): Promise<void> {
    await this.queue.close();
  }
}

export default new MMRQueue();

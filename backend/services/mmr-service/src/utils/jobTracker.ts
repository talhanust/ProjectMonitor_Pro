import RedisClient from '../../../shared/redis/client';
import { logger } from '../../../shared/logger';

export enum JobStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}

export interface JobProgress {
  current: number;
  total: number;
  percentage: number;
  message?: string;
}

export interface JobMetadata {
  jobId: string;
  userId: string;
  fileName: string;
  fileSize: number;
  status: JobStatus;
  progress: JobProgress;
  createdAt: Date;
  startedAt?: Date;
  completedAt?: Date;
  error?: string;
  result?: any;
  retryCount: number;
  maxRetries: number;
}

class JobTracker {
  private redis = RedisClient.getClient();
  private readonly JOB_PREFIX = 'mmr:job:';
  private readonly USER_JOBS_PREFIX = 'mmr:user:jobs:';
  private readonly JOB_TTL = 604800;

  private getJobKey(jobId: string): string {
    return `${this.JOB_PREFIX}${jobId}`;
  }

  private getUserJobsKey(userId: string): string {
    return `${this.USER_JOBS_PREFIX}${userId}`;
  }

  async createJob(
    jobId: string,
    userId: string,
    fileName: string,
    fileSize: number,
  ): Promise<void> {
    const metadata: JobMetadata = {
      jobId,
      userId,
      fileName,
      fileSize,
      status: JobStatus.PENDING,
      progress: { current: 0, total: 100, percentage: 0 },
      createdAt: new Date(),
      retryCount: 0,
      maxRetries: 3,
    };

    await Promise.all([
      this.redis.setex(this.getJobKey(jobId), this.JOB_TTL, JSON.stringify(metadata)),
      this.redis.zadd(this.getUserJobsKey(userId), Date.now(), jobId),
      this.redis.expire(this.getUserJobsKey(userId), this.JOB_TTL),
    ]);
  }

  async updateJobStatus(jobId: string, status: JobStatus, error?: string): Promise<void> {
    const metadata = await this.getJob(jobId);
    if (!metadata) throw new Error(`Job ${jobId} not found`);

    metadata.status = status;
    if (status === JobStatus.PROCESSING && !metadata.startedAt) metadata.startedAt = new Date();
    if ([JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED].includes(status)) {
      metadata.completedAt = new Date();
    }
    if (error) metadata.error = error;

    await this.redis.setex(this.getJobKey(jobId), this.JOB_TTL, JSON.stringify(metadata));
  }

  async updateJobProgress(
    jobId: string,
    current: number,
    total: number,
    message?: string,
  ): Promise<void> {
    const metadata = await this.getJob(jobId);
    if (!metadata) throw new Error(`Job ${jobId} not found`);

    metadata.progress = {
      current,
      total,
      percentage: Math.round((current / total) * 100),
      message,
    };

    await this.redis.setex(this.getJobKey(jobId), this.JOB_TTL, JSON.stringify(metadata));
  }

  async updateJobResult(jobId: string, result: any): Promise<void> {
    const metadata = await this.getJob(jobId);
    if (!metadata) throw new Error(`Job ${jobId} not found`);
    metadata.result = result;
    await this.redis.setex(this.getJobKey(jobId), this.JOB_TTL, JSON.stringify(metadata));
  }

  async incrementRetryCount(jobId: string): Promise<void> {
    const metadata = await this.getJob(jobId);
    if (!metadata) throw new Error(`Job ${jobId} not found`);
    metadata.retryCount += 1;
    await this.redis.setex(this.getJobKey(jobId), this.JOB_TTL, JSON.stringify(metadata));
  }

  async getJob(jobId: string): Promise<JobMetadata | null> {
    const data = await this.redis.get(this.getJobKey(jobId));
    if (!data) return null;

    const metadata = JSON.parse(data);
    metadata.createdAt = new Date(metadata.createdAt);
    if (metadata.startedAt) metadata.startedAt = new Date(metadata.startedAt);
    if (metadata.completedAt) metadata.completedAt = new Date(metadata.completedAt);
    return metadata;
  }

  async getUserJobs(userId: string, limit = 50, offset = 0): Promise<JobMetadata[]> {
    const jobIds = await this.redis.zrevrange(
      this.getUserJobsKey(userId),
      offset,
      offset + limit - 1,
    );
    if (jobIds.length === 0) return [];
    const jobs = await Promise.all(jobIds.map((id) => this.getJob(id)));
    return jobs.filter((job): job is JobMetadata => job !== null);
  }

  async deleteJob(jobId: string): Promise<void> {
    const metadata = await this.getJob(jobId);
    if (!metadata) return;
    await Promise.all([
      this.redis.del(this.getJobKey(jobId)),
      this.redis.zrem(this.getUserJobsKey(metadata.userId), jobId),
    ]);
  }

  async getJobsByStatus(userId: string, status: JobStatus): Promise<JobMetadata[]> {
    const jobs = await this.getUserJobs(userId, 1000);
    return jobs.filter((job) => job.status === status);
  }
}

export default new JobTracker();

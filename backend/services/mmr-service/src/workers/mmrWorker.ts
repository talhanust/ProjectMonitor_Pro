// backend/services/mmr-service/src/workers/mmrWorker.ts

import { Job } from 'bull';
import mmrQueue, { MMRJobData, MMRJobResult } from '../queues/mmrQueue';
import jobTracker, { JobStatus } from '../utils/jobTracker';
import { logger } from '../../../shared/logger';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as XLSX from 'xlsx';
import customMMRWorker from './customMMRWorker';

class MMRWorker {
  private isProcessing = false;

  async start(): Promise<void> {
    const queue = mmrQueue.getQueue();
    queue.process(10, async (job: Job<MMRJobData>) => this.processJob(job));
    this.isProcessing = true;
    logger.info('MMR worker started');
  }

  async stop(): Promise<void> {
    this.isProcessing = false;
    await mmrQueue.close();
  }

  async processJob(job: Job<MMRJobData>): Promise<MMRJobResult> {
    const startTime = Date.now();
    const { jobId, fileName, filePath, uploadId } = job.data;

    try {
      await jobTracker.updateJobStatus(jobId, JobStatus.PROCESSING);
      await job.progress(10);

      const fileBuffer = await fs.readFile(filePath);
      await job.progress(20);

      const fileExtension = path.extname(fileName).toLowerCase();
      let extractedText = '';
      let metadata: any = {};
      let tables: any[] | undefined;
      let mmrData: any[] | undefined;

      if (fileExtension === '.xlsx' || fileExtension === '.xls') {
        // Use custom parser
        const parsed = await customMMRWorker.processProjectMMR(fileBuffer, job);
        extractedText = JSON.stringify(parsed, null, 2);
        metadata = {};
        tables = parsed.rawSheets || [];
        mmrData = [parsed];
      } else {
        extractedText = `File type ${fileExtension} - basic processing`;
        metadata = { fileType: fileExtension };
      }

      await job.progress(90);

      const processingTime = Date.now() - startTime;
      const wordCount = extractedText.split(/\s+/).filter((w) => w.length > 0).length;

      const result: MMRJobResult = {
        jobId,
        uploadId,
        extractedText,
        metadata: { ...metadata, wordCount, processingTime },
        tables,
        mmrData,
      };

      await jobTracker.updateJobResult(jobId, result);
      await jobTracker.updateJobStatus(jobId, JobStatus.COMPLETED);
      await job.progress(100);

      return result;
    } catch (error: any) {
      logger.error(`Job ${jobId} failed:`, error);
      await jobTracker.updateJobStatus(jobId, JobStatus.FAILED, error.message);
      if (job.attemptsMade < job.opts.attempts!) {
        await jobTracker.incrementRetryCount(jobId);
      }
      throw error;
    }
  }

  private async processExcel(
    buffer: Buffer,
    job: Job,
  ): Promise<{
    extractedText: string;
    metadata: any;
    tables: any[];
    mmrData: any[];
  }> {
    await job.progress(30);

    const workbook = XLSX.read(buffer, {
      cellStyles: true,
      cellFormulas: true,
      cellDates: true,
    });

    await job.progress(40);

    const allSheetData: any[] = [];
    const tables: any[] = [];
    let extractedText = '';

    for (const sheetName of workbook.SheetNames) {
      const worksheet = workbook.Sheets[sheetName];
      const jsonData = XLSX.utils.sheet_to_json(worksheet, {
        header: 1,
        defval: '',
        blankrows: false,
      });

      if (jsonData.length > 0) {
        const headers = jsonData[0] as any[];
        const rows = jsonData.slice(1);

        const structuredData = rows.map((row: any) => {
          const record: any = {};
          headers.forEach((header, index) => {
            record[String(header).trim()] = row[index];
          });
          return record;
        });

        allSheetData.push({ sheetName, headers, data: structuredData, rowCount: rows.length });

        const sheetText = structuredData.map((r) => Object.values(r).join(' ')).join('\n');
        extractedText += `\n=== ${sheetName} ===\n${sheetText}\n`;

        tables.push({
          name: sheetName,
          headers,
          rows: structuredData,
          rowCount: rows.length,
          columnCount: headers.length,
        });
      }
    }

    await job.progress(70);

    const mmrData = this.detectMMRStructure(allSheetData);

    await job.progress(80);

    const metadata = {
      sheetCount: workbook.SheetNames.length,
      sheetNames: workbook.SheetNames,
      totalRows: allSheetData.reduce((sum, sheet) => sum + sheet.rowCount, 0),
      isMMRDocument: mmrData.length > 0,
    };

    return { extractedText: extractedText.trim(), metadata, tables, mmrData };
  }

  private detectMMRStructure(sheetData: any[]): any[] {
    const mmrRecords: any[] = [];
    const mmrPatterns = [
      'document',
      'title',
      'category',
      'reference',
      'description',
      'content',
      'tags',
      'source',
      'date',
    ];

    for (const sheet of sheetData) {
      const headers = sheet.headers.map((h: string) => String(h).toLowerCase().trim());
      const hasMMRFields = mmrPatterns.some((pattern) => headers.some((h) => h.includes(pattern)));

      if (hasMMRFields) {
        for (const record of sheet.data) {
          const mmrRecord: any = { sheetSource: sheet.sheetName, rawData: record };

          Object.keys(record).forEach((key) => {
            const lowerKey = key.toLowerCase().trim();
            if (lowerKey.includes('title') || lowerKey.includes('document'))
              mmrRecord.title = record[key];
            if (lowerKey.includes('description') || lowerKey.includes('content'))
              mmrRecord.description = record[key];
            if (lowerKey.includes('category') || lowerKey.includes('type'))
              mmrRecord.category = record[key];
            if (
              lowerKey.includes('reference') ||
              lowerKey.includes('ref') ||
              lowerKey.includes('id')
            )
              mmrRecord.reference = record[key];
            if (lowerKey.includes('date') || lowerKey.includes('created'))
              mmrRecord.date = record[key];
            if (lowerKey.includes('tag') || lowerKey.includes('keyword'))
              mmrRecord.tags = record[key];
            if (lowerKey.includes('source') || lowerKey.includes('url'))
              mmrRecord.source = record[key];
          });

          if (mmrRecord.title || mmrRecord.description) {
            mmrRecords.push(mmrRecord);
          }
        }
      }
    }

    return mmrRecords;
  }

  isRunning(): boolean {
    return this.isProcessing;
  }
}

export default new MMRWorker();

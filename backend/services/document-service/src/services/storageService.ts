import { minioClient, ensureBucket, getPresignedUrl } from '../utils/minio';
import { PrismaClient } from '@prisma/client';
import { v4 as uuidv4 } from 'uuid';
import { validateFile, getFileCategory } from '../utils/fileValidator';

const prisma = new PrismaClient();

export interface UploadedFile {
  fieldname: string;
  filename: string;
  encoding: string;
  mimetype: string;
  buffer: Buffer;
  size: number;
}

export interface UploadOptions {
  projectId?: string;
  category?: string;
  tags?: string[];
  description?: string;
  uploadedBy: string;
}

export class StorageService {
  private bucketName: string;

  constructor() {
    this.bucketName = process.env.MINIO_BUCKET_NAME || 'documents';
    this.initializeBucket();
  }

  private async initializeBucket() {
    await ensureBucket(this.bucketName);
  }

  async uploadFile(file: UploadedFile, options: UploadOptions) {
    try {
      // Determine file category
      const fileCategory = getFileCategory(file.mimetype);

      // Validate file
      if (fileCategory !== 'OTHER') {
        const validation = await validateFile(
          file.buffer,
          file.filename,
          fileCategory as 'PDF' | 'EXCEL' | 'IMAGE',
        );

        if (!validation.valid) {
          throw new Error(validation.error);
        }
      }

      // Generate unique key
      const timestamp = Date.now();
      const uniqueId = uuidv4();
      const extension = file.filename.substring(file.filename.lastIndexOf('.'));
      const key = `${options.category || 'general'}/${timestamp}-${uniqueId}${extension}`;

      // Upload to MinIO
      await minioClient.putObject(this.bucketName, key, file.buffer, file.size, {
        'Content-Type': file.mimetype,
        'X-Original-Name': file.filename,
        'X-Uploaded-By': options.uploadedBy,
        'X-Project-Id': options.projectId || '',
      });

      // Generate presigned URL (valid for 7 days)
      const url = await getPresignedUrl(this.bucketName, key, 7 * 24 * 60 * 60);

      // Save metadata to database
      const document = await prisma.document.create({
        data: {
          fileName: file.filename,
          originalName: file.filename,
          mimeType: file.mimetype,
          size: file.size,
          bucket: this.bucketName,
          key,
          url,
          projectId: options.projectId,
          category: options.category,
          tags: options.tags || [],
          description: options.description,
          uploadedBy: options.uploadedBy,
          status: 'uploaded',
        },
      });

      return document;
    } catch (error) {
      console.error('Upload error:', error);
      throw error;
    }
  }

  async getFile(documentId: string) {
    const document = await prisma.document.findUnique({
      where: { id: documentId },
    });

    if (!document) {
      throw new Error('Document not found');
    }

    // Generate fresh presigned URL
    const url = await getPresignedUrl(this.bucketName, document.key, 3600);

    return {
      ...document,
      url,
    };
  }

  async deleteFile(documentId: string, userId: string) {
    const document = await prisma.document.findUnique({
      where: { id: documentId },
    });

    if (!document) {
      throw new Error('Document not found');
    }

    // Check permissions (simplified - you may want more complex logic)
    if (document.uploadedBy !== userId) {
      throw new Error('Unauthorized to delete this document');
    }

    // Delete from MinIO
    await minioClient.removeObject(this.bucketName, document.key);

    // Delete from database
    await prisma.document.delete({
      where: { id: documentId },
    });

    return { message: 'Document deleted successfully' };
  }

  async listFiles(filters: {
    projectId?: string;
    category?: string;
    uploadedBy?: string;
    page?: number;
    limit?: number;
  }) {
    const { page = 1, limit = 20, ...where } = filters;
    const skip = (page - 1) * limit;

    const [documents, total] = await Promise.all([
      prisma.document.findMany({
        where: where as any,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.document.count({ where: where as any }),
    ]);

    // Generate fresh URLs for all documents
    const documentsWithUrls = await Promise.all(
      documents.map(async (doc) => ({
        ...doc,
        url: await getPresignedUrl(this.bucketName, doc.key, 3600),
      })),
    );

    return {
      documents: documentsWithUrls,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}

export const storageService = new StorageService();

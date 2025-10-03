#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Setting Up Document Upload Infrastructure  ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Create document service directory structure
echo -e "${GREEN}Creating document service structure...${NC}"
mkdir -p backend/services/document-service/{src/{controllers,services,middleware,utils,routes,types},tests}
mkdir -p backend/services/shared/storage

# Create Docker Compose with MinIO
echo -e "${GREEN}Creating Docker Compose with MinIO...${NC}"
cat > docker-compose.yml << 'DOCKER'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: postgres-dev
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: engineering_app
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

  minio:
    image: minio/minio:latest
    container_name: minio-dev
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  postgres_data:
  minio_data:

networks:
  app-network:
    driver: bridge
DOCKER

cd backend/services/document-service

# Create package.json
echo -e "${GREEN}Creating package.json...${NC}"
cat > package.json << 'PACKAGE'
{
  "name": "@backend/document-service",
  "version": "1.0.0",
  "private": true,
  "description": "Document Upload and Processing Service",
  "main": "dist/server.js",
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "vitest"
  },
  "dependencies": {
    "@aws-sdk/client-s3": "^3.450.0",
    "@aws-sdk/s3-request-presigner": "^3.450.0",
    "@prisma/client": "^5.8.0",
    "fastify": "^4.25.2",
    "@fastify/cors": "^8.5.0",
    "@fastify/multipart": "^8.1.0",
    "@fastify/jwt": "^7.2.4",
    "minio": "^7.1.3",
    "file-type": "^18.7.0",
    "dotenv": "^16.3.1",
    "pino": "^8.17.2",
    "uuid": "^9.0.1"
  },
  "devDependencies": {
    "@types/node": "^20.11.0",
    "@types/uuid": "^9.0.7",
    "prisma": "^5.8.0",
    "tsx": "^4.7.0",
    "typescript": "^5.3.3",
    "vitest": "^1.2.0"
  }
}
PACKAGE

npm install

# Create TypeScript config
echo -e "${GREEN}Creating tsconfig.json...${NC}"
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
TSCONFIG

# Create .env file
echo -e "${GREEN}Creating .env file...${NC}"
cat > .env << 'ENV'
PORT=8082
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app?schema=public
JWT_SECRET=your-secret-key-here

# MinIO Configuration
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_USE_SSL=false
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET_NAME=documents

# File Upload Limits
MAX_FILE_SIZE_PDF=20971520
MAX_FILE_SIZE_EXCEL=5242880
MAX_FILE_SIZE_IMAGE=10485760
ENV

# Create Prisma schema
echo -e "${GREEN}Creating Prisma schema...${NC}"
mkdir -p prisma
cat > prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Document {
  id           String   @id @default(cuid())
  fileName     String
  originalName String
  mimeType     String
  size         Int
  bucket       String
  key          String   @unique
  url          String?
  
  // Metadata
  projectId    String?
  category     String?  // PMMS, MMR, etc.
  tags         String[] @default([])
  description  String?
  
  // Upload info
  uploadedBy   String
  uploadedAt   DateTime @default(now())
  
  // Processing status
  status       String   @default("uploaded") // uploaded, processing, processed, failed
  processedAt  DateTime?
  metadata     Json?
  
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  @@index([projectId])
  @@index([category])
  @@index([uploadedBy])
  @@map("documents")
}
PRISMA

# Create MinIO client setup
echo -e "${GREEN}Creating MinIO client...${NC}"
cd ../../shared
cat > storage/minio.ts << 'MINIO'
import * as Minio from 'minio';
import dotenv from 'dotenv';

dotenv.config();

export const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
  secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin'
});

export async function ensureBucket(bucketName: string) {
  try {
    const exists = await minioClient.bucketExists(bucketName);
    if (!exists) {
      await minioClient.makeBucket(bucketName);
      console.log(`Bucket ${bucketName} created successfully`);
    }
  } catch (error) {
    console.error('Error ensuring bucket:', error);
    throw error;
  }
}

export async function getPresignedUrl(bucketName: string, objectName: string, expiry = 3600) {
  try {
    return await minioClient.presignedGetObject(bucketName, objectName, expiry);
  } catch (error) {
    console.error('Error generating presigned URL:', error);
    throw error;
  }
}
MINIO

cd ../document-service

# Create file validator
echo -e "${GREEN}Creating file validator...${NC}"
cat > src/utils/fileValidator.ts << 'VALIDATOR'
import { FastifyRequest } from 'fastify';
import { fileTypeFromBuffer } from 'file-type';

export interface FileValidationOptions {
  maxSize: number;
  allowedMimeTypes: string[];
  allowedExtensions: string[];
}

export const FILE_LIMITS = {
  PDF: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE_PDF || '20971520'), // 20MB
    allowedMimeTypes: ['application/pdf'],
    allowedExtensions: ['.pdf']
  },
  EXCEL: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE_EXCEL || '5242880'), // 5MB
    allowedMimeTypes: [
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.oasis.opendocument.spreadsheet'
    ],
    allowedExtensions: ['.xls', '.xlsx', '.ods']
  },
  IMAGE: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE_IMAGE || '10485760'), // 10MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp']
  }
};

export async function validateFile(
  buffer: Buffer,
  fileName: string,
  category: 'PDF' | 'EXCEL' | 'IMAGE'
): Promise<{ valid: boolean; error?: string }> {
  const limits = FILE_LIMITS[category];
  
  // Check file size
  if (buffer.length > limits.maxSize) {
    return { 
      valid: false, 
      error: `File size exceeds maximum limit of ${limits.maxSize / 1024 / 1024}MB` 
    };
  }
  
  // Check file type from buffer (more secure than trusting headers)
  const fileType = await fileTypeFromBuffer(buffer);
  if (!fileType || !limits.allowedMimeTypes.includes(fileType.mime)) {
    return { 
      valid: false, 
      error: `Invalid file type. Allowed types: ${limits.allowedMimeTypes.join(', ')}` 
    };
  }
  
  // Check file extension
  const extension = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();
  if (!limits.allowedExtensions.includes(extension)) {
    return { 
      valid: false, 
      error: `Invalid file extension. Allowed: ${limits.allowedExtensions.join(', ')}` 
    };
  }
  
  return { valid: true };
}

export function getFileCategory(mimeType: string): 'PDF' | 'EXCEL' | 'IMAGE' | 'OTHER' {
  if (FILE_LIMITS.PDF.allowedMimeTypes.includes(mimeType)) return 'PDF';
  if (FILE_LIMITS.EXCEL.allowedMimeTypes.includes(mimeType)) return 'EXCEL';
  if (FILE_LIMITS.IMAGE.allowedMimeTypes.includes(mimeType)) return 'IMAGE';
  return 'OTHER';
}
VALIDATOR

# Create storage service
echo -e "${GREEN}Creating storage service...${NC}"
cat > src/services/storageService.ts << 'STORAGE'
import { minioClient, ensureBucket, getPresignedUrl } from '../../shared/storage/minio';
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
          fileCategory as 'PDF' | 'EXCEL' | 'IMAGE'
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
      await minioClient.putObject(
        this.bucketName,
        key,
        file.buffer,
        file.size,
        {
          'Content-Type': file.mimetype,
          'X-Original-Name': file.filename,
          'X-Uploaded-By': options.uploadedBy,
          'X-Project-Id': options.projectId || '',
        }
      );

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
          status: 'uploaded'
        }
      });

      return document;
    } catch (error) {
      console.error('Upload error:', error);
      throw error;
    }
  }

  async getFile(documentId: string) {
    const document = await prisma.document.findUnique({
      where: { id: documentId }
    });

    if (!document) {
      throw new Error('Document not found');
    }

    // Generate fresh presigned URL
    const url = await getPresignedUrl(this.bucketName, document.key, 3600);
    
    return {
      ...document,
      url
    };
  }

  async deleteFile(documentId: string, userId: string) {
    const document = await prisma.document.findUnique({
      where: { id: documentId }
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
      where: { id: documentId }
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
        orderBy: { createdAt: 'desc' }
      }),
      prisma.document.count({ where: where as any })
    ]);

    // Generate fresh URLs for all documents
    const documentsWithUrls = await Promise.all(
      documents.map(async (doc) => ({
        ...doc,
        url: await getPresignedUrl(this.bucketName, doc.key, 3600)
      }))
    );

    return {
      documents: documentsWithUrls,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    };
  }
}

export const storageService = new StorageService();
STORAGE

# Create multer middleware
echo -e "${GREEN}Creating upload middleware...${NC}"
cat > src/middleware/multer.ts << 'MULTER'
import { FastifyRequest, FastifyReply } from 'fastify';
import { UploadedFile } from '../services/storageService';

export interface MultipartFile {
  fieldname: string;
  filename: string;
  encoding: string;
  mimetype: string;
  file: NodeJS.ReadableStream;
  _buf?: Buffer;
}

export async function parseMultipart(request: FastifyRequest): Promise<UploadedFile[]> {
  const files: UploadedFile[] = [];
  const parts = (request as any).parts();
  
  for await (const part of parts) {
    if (part.file) {
      const chunks: Buffer[] = [];
      for await (const chunk of part.file) {
        chunks.push(chunk);
      }
      const buffer = Buffer.concat(chunks);
      
      files.push({
        fieldname: part.fieldname,
        filename: part.filename,
        encoding: part.encoding,
        mimetype: part.mimetype,
        buffer,
        size: buffer.length
      });
    }
  }
  
  return files;
}

export async function uploadMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const files = await parseMultipart(request);
    (request as any).files = files;
  } catch (error) {
    reply.status(400).send({ error: 'Invalid multipart data' });
  }
}
MULTER

# Create upload controller
echo -e "${GREEN}Creating upload controller...${NC}"
cat > src/controllers/uploadController.ts << 'CONTROLLER'
import { FastifyRequest, FastifyReply } from 'fastify';
import { storageService, UploadedFile } from '../services/storageService';
import { parseMultipart } from '../middleware/multer';

export class UploadController {
  async uploadSingle(request: FastifyRequest, reply: FastifyReply) {
    try {
      const files = await parseMultipart(request);
      
      if (!files || files.length === 0) {
        return reply.status(400).send({ error: 'No file uploaded' });
      }

      const file = files[0];
      const { projectId, category, tags, description } = request.body as any;
      const userId = (request as any).user?.id || 'anonymous';

      const document = await storageService.uploadFile(file, {
        projectId,
        category,
        tags: tags ? tags.split(',') : [],
        description,
        uploadedBy: userId
      });

      return reply.status(201).send(document);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Upload failed', 
        message: error.message 
      });
    }
  }

  async uploadMultiple(request: FastifyRequest, reply: FastifyReply) {
    try {
      const files = await parseMultipart(request);
      
      if (!files || files.length === 0) {
        return reply.status(400).send({ error: 'No files uploaded' });
      }

      const { projectId, category, tags, description } = request.body as any;
      const userId = (request as any).user?.id || 'anonymous';

      const documents = await Promise.all(
        files.map(file => 
          storageService.uploadFile(file, {
            projectId,
            category,
            tags: tags ? tags.split(',') : [],
            description,
            uploadedBy: userId
          })
        )
      );

      return reply.status(201).send({ documents });
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Upload failed', 
        message: error.message 
      });
    }
  }

  async getDocument(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const document = await storageService.getFile(id);
      return reply.send(document);
    } catch (error: any) {
      if (error.message === 'Document not found') {
        return reply.status(404).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to get document', 
        message: error.message 
      });
    }
  }

  async deleteDocument(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const userId = (request as any).user?.id || 'anonymous';
      
      const result = await storageService.deleteFile(id, userId);
      return reply.send(result);
    } catch (error: any) {
      if (error.message === 'Document not found') {
        return reply.status(404).send({ error: error.message });
      }
      if (error.message.includes('Unauthorized')) {
        return reply.status(403).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to delete document', 
        message: error.message 
      });
    }
  }

  async listDocuments(request: FastifyRequest, reply: FastifyReply) {
    try {
      const query = request.query as {
        projectId?: string;
        category?: string;
        uploadedBy?: string;
        page?: string;
        limit?: string;
      };

      const documents = await storageService.listFiles({
        projectId: query.projectId,
        category: query.category,
        uploadedBy: query.uploadedBy,
        page: query.page ? parseInt(query.page) : 1,
        limit: query.limit ? parseInt(query.limit) : 20
      });

      return reply.send(documents);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Failed to list documents', 
        message: error.message 
      });
    }
  }
}

export const uploadController = new UploadController();
CONTROLLER

# Create routes
echo -e "${GREEN}Creating routes...${NC}"
cat > src/routes/documentRoutes.ts << 'ROUTES'
import { FastifyPluginAsync } from 'fastify';
import { uploadController } from '../controllers/uploadController';

export const documentRoutes: FastifyPluginAsync = async (fastify) => {
  // Upload single file
  fastify.post('/upload', {
    schema: {
      description: 'Upload a single document',
      tags: ['documents'],
      consumes: ['multipart/form-data']
    }
  }, (request, reply) => uploadController.uploadSingle(request, reply));

  // Upload multiple files
  fastify.post('/upload/multiple', {
    schema: {
      description: 'Upload multiple documents',
      tags: ['documents'],
      consumes: ['multipart/form-data']
    }
  }, (request, reply) => uploadController.uploadMultiple(request, reply));

  // Get document
  fastify.get('/:id', {
    schema: {
      description: 'Get document by ID',
      tags: ['documents'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => uploadController.getDocument(request, reply));

  // Delete document
  fastify.delete('/:id', {
    schema: {
      description: 'Delete document',
      tags: ['documents'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => uploadController.deleteDocument(request, reply));

  // List documents
  fastify.get('/', {
    schema: {
      description: 'List documents with filtering',
      tags: ['documents'],
      querystring: {
        type: 'object',
        properties: {
          projectId: { type: 'string' },
          category: { type: 'string' },
          uploadedBy: { type: 'string' },
          page: { type: 'number' },
          limit: { type: 'number' }
        }
      }
    }
  }, (request, reply) => uploadController.listDocuments(request, reply));
};
ROUTES

# Create server
echo -e "${GREEN}Creating server...${NC}"
cat > src/server.ts << 'SERVER'
import fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import multipart from '@fastify/multipart';
import { documentRoutes } from './routes/documentRoutes';
import dotenv from 'dotenv';

dotenv.config();

const server = fastify({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname',
        colorize: true
      }
    }
  }
});

async function start() {
  try {
    // Register plugins
    await server.register(cors, {
      origin: true,
      credentials: true
    });

    await server.register(jwt, {
      secret: process.env.JWT_SECRET || 'your-secret-key'
    });

    await server.register(multipart, {
      limits: {
        fileSize: 20 * 1024 * 1024, // 20MB max
        files: 10 // Max 10 files per request
      }
    });

    // Health check
    server.get('/health', async () => {
      return { 
        status: 'ok', 
        service: 'document-service',
        timestamp: new Date().toISOString() 
      };
    });

    // Register routes
    await server.register(documentRoutes, { prefix: '/api/v1/documents' });

    // Start server
    const port = parseInt(process.env.PORT || '8082');
    await server.listen({ port, host: '0.0.0.0' });
    
    server.log.info(`🚀 Document Service running at http://localhost:${port}`);
    server.log.info(`📚 Health check at http://localhost:${port}/health`);
    server.log.info(`📁 Documents API at http://localhost:${port}/api/v1/documents`);
  } catch (error) {
    server.log.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
SERVER

# Generate Prisma client
echo -e "${GREEN}Generating Prisma client...${NC}"
npx prisma generate

# Create test script
echo -e "${GREEN}Creating test script...${NC}"
cat > test-upload.sh << 'TEST'
#!/bin/bash

API_URL="http://localhost:8082/api/v1/documents"

echo "Testing Document Upload Service"
echo ""

# Create test files
echo "Creating test files..."
echo "This is a test document" > test.txt
echo "PDF content would go here" > test.pdf

# Test single upload
echo "1. Testing single file upload..."
curl -X POST $API_URL/upload \
  -F "file=@test.txt" \
  -F "projectId=test-project-1" \
  -F "category=PMMS" \
  -F "description=Test document"

echo ""
echo "2. Listing documents..."
curl $API_URL

# Cleanup
rm test.txt test.pdf

echo ""
echo "Tests completed!"
TEST
chmod +x test-upload.sh

cd ../../..

# Create Frontend components
echo -e "${GREEN}Creating Frontend upload components...${NC}"
cd frontend

# Create FileUploader component
cat > src/features/shared/components/FileUploader.tsx << 'UPLOADER'
'use client';

import React, { useState, useCallback } from 'react';
import { Upload, X, File, CheckCircle } from 'lucide-react';
import { useFileUpload } from '../hooks/useFileUpload';

interface FileUploaderProps {
  projectId?: string;
  category?: string;
  maxFiles?: number;
  maxSize?: number;
  acceptedTypes?: string[];
  onUploadComplete?: (documents: any[]) => void;
}

export function FileUploader({
  projectId,
  category,
  maxFiles = 10,
  maxSize = 20 * 1024 * 1024, // 20MB default
  acceptedTypes = ['.pdf', '.xls', '.xlsx', '.doc', '.docx'],
  onUploadComplete
}: FileUploaderProps) {
  const [files, setFiles] = useState<File[]>([]);
  const [dragActive, setDragActive] = useState(false);
  
  const { upload, uploading, progress, error } = useFileUpload();

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      handleFiles(e.dataTransfer.files);
    }
  }, []);

  const handleFiles = (fileList: FileList) => {
    const newFiles = Array.from(fileList).filter(file => {
      if (file.size > maxSize) {
        alert(`File ${file.name} exceeds maximum size of ${maxSize / 1024 / 1024}MB`);
        return false;
      }
      return true;
    });
    
    setFiles(prev => [...prev, ...newFiles].slice(0, maxFiles));
  };

  const removeFile = (index: number) => {
    setFiles(prev => prev.filter((_, i) => i !== index));
  };

  const handleUpload = async () => {
    if (files.length === 0) return;
    
    try {
      const documents = await upload(files, {
        projectId,
        category
      });
      
      if (onUploadComplete) {
        onUploadComplete(documents);
      }
      
      setFiles([]);
      # Continue the FileUploader component
cat >> src/features/shared/components/FileUploader.tsx << 'UPLOADER'
    } catch (err) {
      console.error('Upload failed:', err);
    }
  };

  return (
    <div className="w-full">
      <div
        className={`border-2 border-dashed rounded-lg p-6 text-center ${
          dragActive ? 'border-blue-500 bg-blue-50' : 'border-gray-300'
        }`}
        onDragEnter={handleDrag}
        onDragLeave={handleDrag}
        onDragOver={handleDrag}
        onDrop={handleDrop}
      >
        <input
          type="file"
          id="file-upload"
          multiple
          accept={acceptedTypes.join(',')}
          onChange={(e) => e.target.files && handleFiles(e.target.files)}
          className="hidden"
        />
        
        <label htmlFor="file-upload" className="cursor-pointer">
          <Upload className="w-12 h-12 mx-auto text-gray-400 mb-4" />
          <p className="text-lg font-medium mb-2">
            Drag & drop files here or click to browse
          </p>
          <p className="text-sm text-gray-500">
            Maximum {maxFiles} files, up to {maxSize / 1024 / 1024}MB each
          </p>
          <p className="text-xs text-gray-400 mt-1">
            Accepted: {acceptedTypes.join(', ')}
          </p>
        </label>
      </div>

      {files.length > 0 && (
        <div className="mt-4 space-y-2">
          {files.map((file, index) => (
            <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
              <div className="flex items-center">
                <File className="w-5 h-5 mr-3 text-gray-500" />
                <div>
                  <p className="text-sm font-medium">{file.name}</p>
                  <p className="text-xs text-gray-500">
                    {(file.size / 1024).toFixed(2)} KB
                  </p>
                </div>
              </div>
              <button
                onClick={() => removeFile(index)}
                className="p-1 hover:bg-gray-200 rounded"
              >
                <X className="w-4 h-4 text-gray-500" />
              </button>
            </div>
          ))}
        </div>
      )}

      {files.length > 0 && (
        <button
          onClick={handleUpload}
          disabled={uploading}
          className="mt-4 w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
        >
          {uploading ? `Uploading... ${progress}%` : `Upload ${files.length} file(s)`}
        </button>
      )}

      {error && (
        <div className="mt-4 p-3 bg-red-50 text-red-600 rounded-lg">
          {error}
        </div>
      )}
    </div>
  );
}
UPLOADER

# Create useFileUpload hook
echo -e "${GREEN}Creating upload hook...${NC}"
cat > src/features/shared/hooks/useFileUpload.ts << 'HOOK'
'use client';

import { useState } from 'react';
import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_DOCUMENT_API_URL || 'http://localhost:8082';

interface UploadOptions {
  projectId?: string;
  category?: string;
  tags?: string[];
  description?: string;
}

export function useFileUpload() {
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const upload = async (files: File[], options: UploadOptions = {}) => {
    setUploading(true);
    setError(null);
    setProgress(0);

    try {
      const formData = new FormData();
      
      // Add files
      files.forEach(file => {
        formData.append('file', file);
      });

      // Add metadata
      if (options.projectId) formData.append('projectId', options.projectId);
      if (options.category) formData.append('category', options.category);
      if (options.tags) formData.append('tags', options.tags.join(','));
      if (options.description) formData.append('description', options.description);

      const endpoint = files.length > 1 
        ? `${API_URL}/api/v1/documents/upload/multiple`
        : `${API_URL}/api/v1/documents/upload`;

      const response = await axios.post(endpoint, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        onUploadProgress: (progressEvent) => {
          const percentCompleted = Math.round(
            (progressEvent.loaded * 100) / (progressEvent.total || 1)
          );
          setProgress(percentCompleted);
        }
      });

      setUploading(false);
      return files.length > 1 ? response.data.documents : [response.data];
    } catch (err: any) {
      setError(err.response?.data?.message || 'Upload failed');
      setUploading(false);
      throw err;
    }
  };

  const deleteDocument = async (documentId: string) => {
    try {
      await axios.delete(`${API_URL}/api/v1/documents/${documentId}`);
      return true;
    } catch (err: any) {
      setError(err.response?.data?.message || 'Delete failed');
      throw err;
    }
  };

  const getDocument = async (documentId: string) => {
    try {
      const response = await axios.get(`${API_URL}/api/v1/documents/${documentId}`);
      return response.data;
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to get document');
      throw err;
    }
  };

  return {
    upload,
    deleteDocument,
    getDocument,
    uploading,
    progress,
    error
  };
}
HOOK

# Update environment variables
echo -e "${GREEN}Adding document service URL to .env.local...${NC}"
echo "NEXT_PUBLIC_DOCUMENT_API_URL=http://localhost:8082" >> .env.local

cd ..

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}   Document Upload Infrastructure Complete!    ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}To start the document service:${NC}"
echo ""
echo "1. Start MinIO (for file storage):"
echo "   ${BLUE}docker-compose up -d minio${NC}"
echo ""
echo "2. Access MinIO console:"
echo "   URL: http://localhost:9001"
echo "   Username: minioadmin"
echo "   Password: minioadmin"
echo ""
echo "3. Initialize database:"
echo "   ${BLUE}cd backend/services/document-service${NC}"
echo "   ${BLUE}npx prisma db push${NC}"
echo ""
echo "4. Start the document service:"
echo "   ${BLUE}npm run dev${NC}"
echo ""
echo -e "${GREEN}Features implemented:${NC}"
echo "  ✅ File upload with validation (20MB PDF, 5MB Excel)"
echo "  ✅ MinIO/S3 compatible storage"
echo "  ✅ Metadata tracking in PostgreSQL"
echo "  ✅ Presigned URLs for secure access"
echo "  ✅ Multiple file upload support"
echo "  ✅ Project and category association"
echo "  ✅ Frontend upload component with drag & drop"
echo ""
echo -e "${YELLOW}API Endpoints:${NC}"
echo "  POST   /api/v1/documents/upload         - Upload single file"
echo "  POST   /api/v1/documents/upload/multiple - Upload multiple files"
echo "  GET    /api/v1/documents               - List documents"
echo "  GET    /api/v1/documents/:id           - Get document"
echo "  DELETE /api/v1/documents/:id           - Delete document"

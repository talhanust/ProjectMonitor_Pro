#!/bin/bash

cd backend/services/document-service

echo "Fixing MinIO import path..."

# Create the MinIO client in the document service directly
cat > src/utils/minio.ts << 'MINIO'
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

# Update the storage service to use the correct import path
sed -i "s|import { minioClient, ensureBucket, getPresignedUrl } from '../../shared/storage/minio';|import { minioClient, ensureBucket, getPresignedUrl } from '../utils/minio';|" src/services/storageService.ts

echo "✅ Fixed import path"
echo ""
echo "Now starting the document service..."
npm run dev

#!/bin/bash

echo "Fixing missing files and directories..."

# Fix MinIO client in the correct location
echo "Creating shared storage directory and MinIO client..."
mkdir -p backend/services/shared/storage
cat > backend/services/shared/storage/minio.ts << 'MINIO'
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

# Fix frontend directories and files
echo "Creating frontend shared components..."
mkdir -p frontend/src/features/shared/{components,hooks}

cat > frontend/src/features/shared/components/FileUploader.tsx << 'UPLOADER'
'use client';

import React, { useState, useCallback } from 'react';
import { Upload, X, File } from 'lucide-react';
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
  maxSize = 20 * 1024 * 1024,
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
      const documents = await upload(files, { projectId, category });
      if (onUploadComplete) {
        onUploadComplete(documents);
      }
      setFiles([]);
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
          
          <button
            onClick={handleUpload}
            disabled={uploading}
            className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
          >
            {uploading ? `Uploading... ${progress}%` : `Upload ${files.length} file(s)`}
          </button>
        </div>
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

cat > frontend/src/features/shared/hooks/useFileUpload.ts << 'HOOK'
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
      files.forEach(file => formData.append('file', file));
      
      if (options.projectId) formData.append('projectId', options.projectId);
      if (options.category) formData.append('category', options.category);
      if (options.tags) formData.append('tags', options.tags.join(','));
      if (options.description) formData.append('description', options.description);

      const endpoint = files.length > 1 
        ? `${API_URL}/api/v1/documents/upload/multiple`
        : `${API_URL}/api/v1/documents/upload`;

      const response = await axios.post(endpoint, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
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

  return { upload, uploading, progress, error };
}
HOOK

echo "✅ All files fixed successfully!"
echo ""
echo "Now you can:"
echo "1. Start MinIO: docker-compose up -d minio"
echo "2. Initialize DB: cd backend/services/document-service && npx prisma db push"
echo "3. Start service: npm run dev"

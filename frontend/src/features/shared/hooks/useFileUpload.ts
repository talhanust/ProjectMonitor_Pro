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

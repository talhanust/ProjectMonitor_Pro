import { useState, useCallback } from 'react';
import { mmrService } from '../services/mmrService';
import { useWebSocket } from '@/lib/websocket';

interface Job {
  id: string;
  fileName: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  progress: number;
  error?: string;
  result?: any;
}

export function useMMRProcessing() {
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(false);

  // Handle WebSocket messages
  const handleMessage = useCallback((data: any) => {
    if (data.type === 'job:update') {
      setJobs(prev => prev.map(job => 
        job.id === data.jobId 
          ? { ...job, status: data.status, progress: data.progress, result: data.result }
          : job
      ));
    }
  }, []);

  const { sendMessage } = useWebSocket(handleMessage);

  const processFiles = useCallback(async (files: File[]) => {
    setLoading(true);
    try {
      for (const file of files) {
        const jobId = crypto.randomUUID();
        
        // Add job to state immediately
        setJobs(prev => [...prev, {
          id: jobId,
          fileName: file.name,
          status: 'pending' as const,
          progress: 0
        }]);

        try {
          await mmrService.uploadFile(file, (progress) => {
            setJobs(prev => prev.map(job => 
              job.id === jobId ? { ...job, progress } : job
            ));
          });
          
          setJobs(prev => prev.map(job => 
            job.id === jobId ? { ...job, status: 'completed', progress: 100 } : job
          ));
        } catch (error) {
          setJobs(prev => prev.map(job => 
            job.id === jobId 
              ? { ...job, status: 'failed', error: error instanceof Error ? error.message : 'Upload failed' } 
              : job
          ));
          console.error(`Error uploading ${file.name}:`, error);
        }
      }
    } catch (error) {
      console.error('Error processing files:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  const getJobStatus = useCallback(async (jobId: string) => {
    try {
      const status = await mmrService.getProcessingStatus(jobId);
      setJobs(prev => prev.map(job => 
        job.id === jobId ? { ...job, ...status } : job
      ));
    } catch (error) {
      console.error('Error getting job status:', error);
    }
  }, []);

  return {
    jobs,
    loading,
    processFiles,
    getJobStatus
  };
}

'use client';

import { useEffect, useState } from 'react';
import { CheckCircle, Clock, AlertCircle, Loader2 } from 'lucide-react';

interface QueueJob {
  id: string;
  fileName: string;
  status: 'pending' | 'processing' | 'completed' | 'failed';
  progress: number;
  error?: string;
}

interface ProcessingQueueProps {
  jobs: QueueJob[];
  onJobClick?: (job: QueueJob) => void;
}

export function ProcessingQueue({ jobs, onJobClick }: ProcessingQueueProps) {
  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'processing':
        return <Loader2 className="h-5 w-5 text-blue-600 animate-spin" />;
      case 'failed':
        return <AlertCircle className="h-5 w-5 text-red-600" />;
      default:
        return <Clock className="h-5 w-5 text-gray-400" />;
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'completed': return 'Completed';
      case 'processing': return 'Processing';
      case 'failed': return 'Failed';
      default: return 'Pending';
    }
  };

  return (
    <div className="space-y-2">
      <h3 className="font-semibold text-lg mb-4">Processing Queue ({jobs.length})</h3>
      
      {jobs.length === 0 ? (
        <p className="text-sm text-gray-500 text-center py-8">No jobs in queue</p>
      ) : (
        jobs.map(job => (
          <div
            key={job.id}
            onClick={() => onJobClick?.(job)}
            className="flex items-center gap-3 p-4 bg-white border rounded-lg hover:bg-gray-50 cursor-pointer"
          >
            {getStatusIcon(job.status)}
            
            <div className="flex-1">
              <p className="font-medium text-sm">{job.fileName}</p>
              <div className="flex items-center gap-2 mt-1">
                <p className="text-xs text-gray-500">{getStatusText(job.status)}</p>
                {job.status === 'processing' && (
                  <div className="flex-1 max-w-xs">
                    <div className="h-1 bg-gray-200 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-blue-600 transition-all"
                        style={{ width: `${job.progress}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
              {job.error && (
                <p className="text-xs text-red-600 mt-1">{job.error}</p>
              )}
            </div>

            {job.status === 'processing' && (
              <span className="text-xs text-gray-500">{job.progress}%</span>
            )}
          </div>
        ))
      )}
    </div>
  );
}

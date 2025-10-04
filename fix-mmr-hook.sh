#!/bin/bash

# MMR Hook Fix Script
# Fixes the "subscribe is not a function" error

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           MMR Hook Fix - Subscribe Error                            ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Navigate to frontend
cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Fixing useMMRProcessing hook..."

# Update the hook to work with the correct WebSocket implementation
cat > src/features/mmr/hooks/useMMRProcessing.ts << 'EOF'
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
EOF

echo -e "${GREEN}✓${NC} Hook fixed"

echo -e "${BLUE}[2/2]${NC} Restarting frontend..."

# Kill existing frontend
if sudo netstat -tulnp | grep -q 3000; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ Hook Fixed!                                     ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. ${BLUE}npm run dev${NC}"
echo "  2. Navigate to: ${GREEN}/mmr${NC}"
echo "  3. The 'subscribe is not a function' error should be gone"
echo ""
echo "What was fixed:"
echo "  ✓ Removed subscribe/unsubscribe (not supported)"
echo "  ✓ Using useWebSocket with callback instead"
echo "  ✓ Direct file upload with progress tracking"
echo ""
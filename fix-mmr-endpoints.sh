#!/bin/bash

# MMR Endpoint Fix Script
# Updates API endpoints to match actual MMR service routes

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           MMR Service Endpoint Fix                                  ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Updating mmrService with correct endpoints..."

cat > src/features/mmr/services/mmrService.ts << 'EOF'
const API_URL = process.env.NEXT_PUBLIC_MMR_API_URL || 'http://localhost:3001';

export const mmrService = {
  async uploadFile(file: File, onProgress?: (progress: number) => void) {
    const formData = new FormData();
    formData.append('file', file);

    const xhr = new XMLHttpRequest();

    return new Promise((resolve, reject) => {
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable && onProgress) {
          const progress = (e.loaded / e.total) * 100;
          onProgress(progress);
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status === 200) {
          try {
            const response = JSON.parse(xhr.responseText);
            resolve(response);
          } catch (e) {
            reject(new Error('Invalid response from server'));
          }
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`));
        }
      });

      xhr.addEventListener('error', () => reject(new Error('Network error during upload')));
      
      // Use the correct endpoint: /api/v1/mmr/parse
      xhr.open('POST', `${API_URL}/api/v1/mmr/parse`);
      xhr.send(formData);
    });
  },

  async getProcessingStatus(fileId: string) {
    const response = await fetch(`${API_URL}/jobs/${fileId}`);
    if (!response.ok) throw new Error('Failed to get status');
    return response.json();
  },

  async getValidationResults(fileId: string) {
    const response = await fetch(`${API_URL}/jobs/${fileId}`);
    if (!response.ok) throw new Error('Failed to get validation results');
    return response.json();
  },

  async correctData(fileId: string, corrections: any) {
    const response = await fetch(`${API_URL}/jobs/${fileId}/correct`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(corrections),
    });
    if (!response.ok) throw new Error('Failed to correct data');
    return response.json();
  },

  async approveData(fileId: string) {
    const response = await fetch(`${API_URL}/jobs/${fileId}/approve`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to approve data');
    return response.json();
  },
};
EOF

echo -e "${GREEN}✓${NC} mmrService updated with correct endpoints"

echo -e "${BLUE}[2/2]${NC} Restarting frontend..."

if sudo netstat -tulnp | grep -q 3000 2>/dev/null; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ Endpoints Fixed!                                ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Navigate to: /mmr"
echo "  3. Upload an Excel file (.xlsx or .xls)"
echo ""
echo "What was fixed:"
echo "  ✓ Upload endpoint: /api/mmr/upload → /api/v1/mmr/parse"
echo "  ✓ Status endpoint: /api/mmr/status → /jobs"
echo "  ✓ Better error handling"
echo ""
echo "The MMR service endpoints:"
echo "  📤 POST /api/v1/mmr/parse - Upload and parse MMR files"
echo "  📊 GET  /jobs/:jobId      - Get job status"
echo "  📋 GET  /jobs             - Get all jobs"
echo ""
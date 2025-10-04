#!/bin/bash

# MMR Page Prop Fix Script
# Fixes the onFilesSelected prop error

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           MMR Page Fix - onFilesSelected Prop                       ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Updating MMR page with correct props..."

cat > 'app/(dashboard)/mmr/page.tsx' << 'EOF'
'use client';
import { useState } from 'react';
import { MMRUploader } from '@/features/mmr/components/MMRUploader';
import { ProcessingQueue } from '@/features/mmr/components/ProcessingQueue';
import { ValidationPanel } from '@/features/mmr/components/ValidationPanel';
import { DataCorrection } from '@/features/mmr/components/DataCorrection';
import { useMMRProcessing } from '@/features/mmr/hooks/useMMRProcessing';

export default function MMRPage() {
  const { jobs, processFiles } = useMMRProcessing();
  const [showCorrection, setShowCorrection] = useState(false);

  const handleFilesSelected = async (files: File[]) => {
    await processFiles(files);
  };

  return (
    <div className="container mx-auto py-8 px-4">
      <h1 className="text-3xl font-bold mb-8">MMR Processing</h1>
      
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <MMRUploader onFilesSelected={handleFilesSelected} />
          <ProcessingQueue jobs={jobs} />
        </div>
        
        <div className="space-y-6">
          <ValidationPanel results={[]} />
          {showCorrection && (
            <DataCorrection
              fields={[]}
              onSave={() => setShowCorrection(false)}
              onCancel={() => setShowCorrection(false)}
            />
          )}
        </div>
      </div>
    </div>
  );
}
EOF

echo -e "${GREEN}✓${NC} MMR page updated"

echo -e "${BLUE}[2/2]${NC} Restarting frontend..."

if sudo netstat -tulnp | grep -q 3000 2>/dev/null; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ Page Fixed!                                     ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Navigate to: /mmr"
echo "  3. Upload Excel files"
echo ""
echo "What was fixed:"
echo "  ✓ Changed onUploadComplete → onFilesSelected"
echo "  ✓ Simplified file handling"
echo "  ✓ Direct integration with processFiles"
echo ""
#!/bin/bash

# MMR Uploader Fix Script
# Fixes file upload functionality

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           MMR Uploader Fix - Enable File Upload                     ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Updating MMRUploader component..."

cat > src/features/mmr/components/MMRUploader.tsx << 'EOF'
'use client';

import { useState, useCallback, useRef } from 'react';
import { Upload, X, FileSpreadsheet, CheckCircle, AlertCircle } from 'lucide-react';

interface UploadFile {
  id: string;
  file: File;
  status: 'pending' | 'uploading' | 'uploaded' | 'error';
  progress: number;
  error?: string;
}

interface MMRUploaderProps {
  onFilesSelected: (files: File[]) => void;
  maxFiles?: number;
  maxSize?: number;
}

export function MMRUploader({ 
  onFilesSelected, 
  maxFiles = 10,
  maxSize = 100 * 1024 * 1024
}: MMRUploaderProps) {
  const [files, setFiles] = useState<UploadFile[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const validateFile = useCallback((file: File): string | null => {
    const validTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel'
    ];
    
    if (!validTypes.includes(file.type) && !file.name.endsWith('.xlsx') && !file.name.endsWith('.xls')) {
      return 'Only Excel files (.xlsx, .xls) are supported';
    }

    if (file.size > maxSize) {
      return `File size exceeds ${maxSize / 1024 / 1024}MB limit`;
    }

    return null;
  }, [maxSize]);

  const handleFiles = useCallback((newFiles: FileList | File[]) => {
    const fileArray = Array.from(newFiles);
    
    if (files.length + fileArray.length > maxFiles) {
      alert(`Maximum ${maxFiles} files allowed`);
      return;
    }

    const uploadFiles: UploadFile[] = fileArray.map(file => {
      const error = validateFile(file);
      return {
        id: `${file.name}-${Date.now()}-${Math.random()}`,
        file,
        status: error ? 'error' : 'pending',
        progress: 0,
        error
      };
    });

    const newFileList = [...files, ...uploadFiles];
    setFiles(newFileList);
    
    // Immediately trigger upload for valid files
    const validFiles = uploadFiles.filter(f => !f.error).map(f => f.file);
    if (validFiles.length > 0) {
      onFilesSelected(validFiles);
    }
  }, [files, maxFiles, onFilesSelected, validateFile]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files) {
      handleFiles(e.dataTransfer.files);
    }
  }, [handleFiles]);

  const removeFile = (id: string) => {
    setFiles(prev => prev.filter(f => f.id !== id));
  };

  return (
    <div className="space-y-4">
      <div
        onDrop={handleDrop}
        onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
        onDragLeave={(e) => { e.preventDefault(); setIsDragging(false); }}
        className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors cursor-pointer ${
          isDragging ? 'border-blue-500 bg-blue-50' : 'border-gray-300 hover:border-gray-400'
        }`}
        onClick={() => fileInputRef.current?.click()}
      >
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept=".xlsx,.xls"
          onChange={(e) => e.target.files && handleFiles(e.target.files)}
          className="hidden"
        />
        <Upload className="mx-auto h-12 w-12 text-gray-400" />
        <p className="mt-2 text-sm text-gray-600">
          Drag and drop MMR files or click to browse
        </p>
        <p className="mt-1 text-xs text-gray-500">
          Supports .xlsx and .xls files up to {maxSize / 1024 / 1024}MB
        </p>
      </div>

      {files.length > 0 && (
        <div className="space-y-2">
          <h4 className="text-sm font-medium text-gray-700">Selected Files ({files.length})</h4>
          {files.map(file => (
            <div key={file.id} className="flex items-center gap-3 p-3 bg-gray-50 rounded-lg border">
              <FileSpreadsheet className={`h-6 w-6 ${file.error ? 'text-red-500' : 'text-green-600'}`} />
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">{file.file.name}</p>
                <p className="text-xs text-gray-500">
                  {(file.file.size / 1024 / 1024).toFixed(2)} MB
                  {file.error && <span className="text-red-500 ml-2">• {file.error}</span>}
                </p>
              </div>
              {file.status === 'uploaded' && <CheckCircle className="h-5 w-5 text-green-500" />}
              {file.error && <AlertCircle className="h-5 w-5 text-red-500" />}
              <button 
                onClick={(e) => { e.stopPropagation(); removeFile(file.id); }}
                className="p-1 hover:bg-gray-200 rounded"
              >
                <X className="h-4 w-4 text-gray-500" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
EOF

echo -e "${GREEN}✓${NC} MMRUploader component updated"

echo -e "${BLUE}[2/2]${NC} Restarting frontend..."

if sudo netstat -tulnp | grep -q 3000 2>/dev/null; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ Uploader Fixed!                                 ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. ${BLUE}npm run dev${NC}"
echo "  2. Navigate to: ${GREEN}/mmr${NC}"
echo "  3. Try uploading Excel files"
echo ""
echo "What was fixed:"
echo "  ✓ Files now upload immediately when selected"
echo "  ✓ Click anywhere in drop zone to browse files"
echo "  ✓ Better visual feedback with icons"
echo "  ✓ Validation errors shown clearly"
echo ""
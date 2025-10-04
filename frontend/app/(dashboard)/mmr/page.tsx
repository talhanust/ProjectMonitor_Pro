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

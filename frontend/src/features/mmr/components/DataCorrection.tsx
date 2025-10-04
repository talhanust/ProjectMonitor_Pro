'use client';

import { useState } from 'react';
import { Save, X } from 'lucide-react';

interface CorrectionField {
  row: number;
  field: string;
  currentValue: string;
  suggestedValue?: string;
}

interface DataCorrectionProps {
  fields: CorrectionField[];
  onSave: (corrections: Record<string, string>) => void;
  onCancel: () => void;
}

export function DataCorrection({ fields, onSave, onCancel }: DataCorrectionProps) {
  const [corrections, setCorrections] = useState<Record<string, string>>({});

  const handleChange = (key: string, value: string) => {
    setCorrections(prev => ({ ...prev, [key]: value }));
  };

  const handleSave = () => {
    onSave(corrections);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-lg">Manual Corrections</h3>
        <button onClick={onCancel} className="text-gray-500 hover:text-gray-700">
          <X className="h-5 w-5" />
        </button>
      </div>

      <div className="space-y-3">
        {fields.map((field, index) => {
          const key = `${field.row}-${field.field}`;
          return (
            <div key={index} className="p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center justify-between mb-2">
                <p className="text-sm font-medium">Row {field.row} - {field.field}</p>
              </div>
              
              <div className="space-y-2">
                <div>
                  <label className="text-xs text-gray-500">Current Value</label>
                  <p className="text-sm">{field.currentValue || '(empty)'}</p>
                </div>
                
                {field.suggestedValue && (
                  <div>
                    <label className="text-xs text-gray-500">Suggested Value</label>
                    <p className="text-sm text-green-600">{field.suggestedValue}</p>
                  </div>
                )}
                
                <div>
                  <label className="text-xs text-gray-500 block mb-1">New Value</label>
                  <input
                    type="text"
                    value={corrections[key] || field.suggestedValue || ''}
                    onChange={(e) => handleChange(key, e.target.value)}
                    className="w-full px-3 py-2 border rounded-md text-sm"
                    placeholder="Enter corrected value"
                  />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="flex gap-2 justify-end">
        <button
          onClick={onCancel}
          className="px-4 py-2 text-sm border rounded-md hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          onClick={handleSave}
          className="px-4 py-2 text-sm bg-primary text-white rounded-md hover:bg-primary/90 flex items-center gap-2"
        >
          <Save className="h-4 w-4" />
          Save Corrections
        </button>
      </div>
    </div>
  );
}

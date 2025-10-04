'use client';

import { AlertTriangle, CheckCircle, Info } from 'lucide-react';

interface ValidationResult {
  type: 'error' | 'warning' | 'info';
  message: string;
  field?: string;
  row?: number;
}

interface ValidationPanelProps {
  results: ValidationResult[];
  onFixClick?: (result: ValidationResult) => void;
}

export function ValidationPanel({ results, onFixClick }: ValidationPanelProps) {
  const getIcon = (type: string) => {
    switch (type) {
      case 'error':
        return <AlertTriangle className="h-5 w-5 text-red-600" />;
      case 'warning':
        return <AlertTriangle className="h-5 w-5 text-yellow-600" />;
      default:
        return <Info className="h-5 w-5 text-blue-600" />;
    }
  };

  const getBgColor = (type: string) => {
    switch (type) {
      case 'error': return 'bg-red-50 border-red-200';
      case 'warning': return 'bg-yellow-50 border-yellow-200';
      default: return 'bg-blue-50 border-blue-200';
    }
  };

  const errorCount = results.filter(r => r.type === 'error').length;
  const warningCount = results.filter(r => r.type === 'warning').length;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-lg">Validation Results</h3>
        <div className="flex gap-4 text-sm">
          {errorCount > 0 && (
            <span className="text-red-600">{errorCount} errors</span>
          )}
          {warningCount > 0 && (
            <span className="text-yellow-600">{warningCount} warnings</span>
          )}
        </div>
      </div>

      {results.length === 0 ? (
        <div className="flex items-center gap-2 p-4 bg-green-50 border border-green-200 rounded-lg">
          <CheckCircle className="h-5 w-5 text-green-600" />
          <p className="text-sm text-green-800">All validations passed</p>
        </div>
      ) : (
        <div className="space-y-2">
          {results.map((result, index) => (
            <div
              key={index}
              className={`flex items-start gap-3 p-3 border rounded-lg ${getBgColor(result.type)}`}
            >
              {getIcon(result.type)}
              <div className="flex-1">
                <p className="text-sm font-medium">{result.message}</p>
                {(result.field || result.row) && (
                  <p className="text-xs text-gray-600 mt-1">
                    {result.field && `Field: ${result.field}`}
                    {result.field && result.row && ' | '}
                    {result.row && `Row: ${result.row}`}
                  </p>
                )}
              </div>
              {result.type === 'error' && onFixClick && (
                <button
                  onClick={() => onFixClick(result)}
                  className="text-xs text-primary hover:underline"
                >
                  Fix
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

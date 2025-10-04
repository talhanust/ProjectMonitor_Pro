import { FastifyRequest } from 'fastify';
import { fileTypeFromBuffer } from 'file-type';

export interface FileValidationOptions {
  maxSize: number;
  allowedMimeTypes: string[];
  allowedExtensions: string[];
}

export const FILE_LIMITS = {
  PDF: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE_PDF || '20971520'), // 20MB
    allowedMimeTypes: ['application/pdf'],
    allowedExtensions: ['.pdf'],
  },
  EXCEL: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE_EXCEL || '5242880'), // 5MB
    allowedMimeTypes: [
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.oasis.opendocument.spreadsheet',
    ],
    allowedExtensions: ['.xls', '.xlsx', '.ods'],
  },
  IMAGE: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE_IMAGE || '10485760'), // 10MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
    allowedExtensions: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
  },
};

export async function validateFile(
  buffer: Buffer,
  fileName: string,
  category: 'PDF' | 'EXCEL' | 'IMAGE',
): Promise<{ valid: boolean; error?: string }> {
  const limits = FILE_LIMITS[category];

  // Check file size
  if (buffer.length > limits.maxSize) {
    return {
      valid: false,
      error: `File size exceeds maximum limit of ${limits.maxSize / 1024 / 1024}MB`,
    };
  }

  // Check file type from buffer (more secure than trusting headers)
  const fileType = await fileTypeFromBuffer(buffer);
  if (!fileType || !limits.allowedMimeTypes.includes(fileType.mime)) {
    return {
      valid: false,
      error: `Invalid file type. Allowed types: ${limits.allowedMimeTypes.join(', ')}`,
    };
  }

  // Check file extension
  const extension = fileName.substring(fileName.lastIndexOf('.')).toLowerCase();
  if (!limits.allowedExtensions.includes(extension)) {
    return {
      valid: false,
      error: `Invalid file extension. Allowed: ${limits.allowedExtensions.join(', ')}`,
    };
  }

  return { valid: true };
}

export function getFileCategory(mimeType: string): 'PDF' | 'EXCEL' | 'IMAGE' | 'OTHER' {
  if (FILE_LIMITS.PDF.allowedMimeTypes.includes(mimeType)) return 'PDF';
  if (FILE_LIMITS.EXCEL.allowedMimeTypes.includes(mimeType)) return 'EXCEL';
  if (FILE_LIMITS.IMAGE.allowedMimeTypes.includes(mimeType)) return 'IMAGE';
  return 'OTHER';
}

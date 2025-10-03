import { FastifyRequest, FastifyReply } from 'fastify';
import { UploadedFile } from '../services/storageService';

export interface MultipartFile {
  fieldname: string;
  filename: string;
  encoding: string;
  mimetype: string;
  file: NodeJS.ReadableStream;
  _buf?: Buffer;
}

export async function parseMultipart(request: FastifyRequest): Promise<UploadedFile[]> {
  const files: UploadedFile[] = [];
  const parts = (request as any).parts();
  
  for await (const part of parts) {
    if (part.file) {
      const chunks: Buffer[] = [];
      for await (const chunk of part.file) {
        chunks.push(chunk);
      }
      const buffer = Buffer.concat(chunks);
      
      files.push({
        fieldname: part.fieldname,
        filename: part.filename,
        encoding: part.encoding,
        mimetype: part.mimetype,
        buffer,
        size: buffer.length
      });
    }
  }
  
  return files;
}

export async function uploadMiddleware(
  request: FastifyRequest,
  reply: FastifyReply
) {
  try {
    const files = await parseMultipart(request);
    (request as any).files = files;
  } catch (error) {
    reply.status(400).send({ error: 'Invalid multipart data' });
  }
}

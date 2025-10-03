import { FastifyRequest, FastifyReply } from 'fastify';
import { storageService, UploadedFile } from '../services/storageService';
import { parseMultipart } from '../middleware/multer';

export class UploadController {
  async uploadSingle(request: FastifyRequest, reply: FastifyReply) {
    try {
      const files = await parseMultipart(request);
      
      if (!files || files.length === 0) {
        return reply.status(400).send({ error: 'No file uploaded' });
      }

      const file = files[0];
      const { projectId, category, tags, description } = request.body as any;
      const userId = (request as any).user?.id || 'anonymous';

      const document = await storageService.uploadFile(file, {
        projectId,
        category,
        tags: tags ? tags.split(',') : [],
        description,
        uploadedBy: userId
      });

      return reply.status(201).send(document);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Upload failed', 
        message: error.message 
      });
    }
  }

  async uploadMultiple(request: FastifyRequest, reply: FastifyReply) {
    try {
      const files = await parseMultipart(request);
      
      if (!files || files.length === 0) {
        return reply.status(400).send({ error: 'No files uploaded' });
      }

      const { projectId, category, tags, description } = request.body as any;
      const userId = (request as any).user?.id || 'anonymous';

      const documents = await Promise.all(
        files.map(file => 
          storageService.uploadFile(file, {
            projectId,
            category,
            tags: tags ? tags.split(',') : [],
            description,
            uploadedBy: userId
          })
        )
      );

      return reply.status(201).send({ documents });
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Upload failed', 
        message: error.message 
      });
    }
  }

  async getDocument(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const document = await storageService.getFile(id);
      return reply.send(document);
    } catch (error: any) {
      if (error.message === 'Document not found') {
        return reply.status(404).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to get document', 
        message: error.message 
      });
    }
  }

  async deleteDocument(request: FastifyRequest, reply: FastifyReply) {
    try {
      const { id } = request.params as { id: string };
      const userId = (request as any).user?.id || 'anonymous';
      
      const result = await storageService.deleteFile(id, userId);
      return reply.send(result);
    } catch (error: any) {
      if (error.message === 'Document not found') {
        return reply.status(404).send({ error: error.message });
      }
      if (error.message.includes('Unauthorized')) {
        return reply.status(403).send({ error: error.message });
      }
      return reply.status(500).send({ 
        error: 'Failed to delete document', 
        message: error.message 
      });
    }
  }

  async listDocuments(request: FastifyRequest, reply: FastifyReply) {
    try {
      const query = request.query as {
        projectId?: string;
        category?: string;
        uploadedBy?: string;
        page?: string;
        limit?: string;
      };

      const documents = await storageService.listFiles({
        projectId: query.projectId,
        category: query.category,
        uploadedBy: query.uploadedBy,
        page: query.page ? parseInt(query.page) : 1,
        limit: query.limit ? parseInt(query.limit) : 20
      });

      return reply.send(documents);
    } catch (error: any) {
      return reply.status(500).send({ 
        error: 'Failed to list documents', 
        message: error.message 
      });
    }
  }
}

export const uploadController = new UploadController();

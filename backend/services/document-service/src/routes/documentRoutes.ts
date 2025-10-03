import { FastifyPluginAsync } from 'fastify';
import { uploadController } from '../controllers/uploadController';

export const documentRoutes: FastifyPluginAsync = async (fastify) => {
  // Upload single file
  fastify.post('/upload', {
    schema: {
      description: 'Upload a single document',
      tags: ['documents'],
      consumes: ['multipart/form-data']
    }
  }, (request, reply) => uploadController.uploadSingle(request, reply));

  // Upload multiple files
  fastify.post('/upload/multiple', {
    schema: {
      description: 'Upload multiple documents',
      tags: ['documents'],
      consumes: ['multipart/form-data']
    }
  }, (request, reply) => uploadController.uploadMultiple(request, reply));

  // Get document
  fastify.get('/:id', {
    schema: {
      description: 'Get document by ID',
      tags: ['documents'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => uploadController.getDocument(request, reply));

  // Delete document
  fastify.delete('/:id', {
    schema: {
      description: 'Delete document',
      tags: ['documents'],
      params: {
        type: 'object',
        properties: {
          id: { type: 'string' }
        }
      }
    }
  }, (request, reply) => uploadController.deleteDocument(request, reply));

  // List documents
  fastify.get('/', {
    schema: {
      description: 'List documents with filtering',
      tags: ['documents'],
      querystring: {
        type: 'object',
        properties: {
          projectId: { type: 'string' },
          category: { type: 'string' },
          uploadedBy: { type: 'string' },
          page: { type: 'number' },
          limit: { type: 'number' }
        }
      }
    }
  }, (request, reply) => uploadController.listDocuments(request, reply));
};

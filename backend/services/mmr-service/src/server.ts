import fastify from 'fastify';
import cors from '@fastify/cors';
import multipart from '@fastify/multipart';
import { ExcelProcessor } from './processors/excelProcessor';
import { MMRValidator } from './validators/mmrValidator';
import dotenv from 'dotenv';

dotenv.config();

const server = fastify({
  logger: {
    level: 'info',
    transport: {
      target: 'pino-pretty',
      options: {
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname',
        colorize: true,
      },
    },
  },
});

async function start() {
  try {
    await server.register(cors, {
      origin: true,
      credentials: true,
    });

    // 🔧 increase file upload size + safety limits
    await server.register(multipart, {
      limits: {
        fileSize: 20 * 1024 * 1024, // 20 MB max file
        files: 1, // allow only 1 file
        fields: 5, // small number of extra fields
      },
    });

    // Health check
    server.get('/health', async () => ({
      status: 'ok',
      service: 'mmr-service',
      timestamp: new Date().toISOString(),
    }));

    // Parse MMR endpoint
    server.post('/api/v1/mmr/parse', async (request, reply) => {
      const data = await request.file();
      if (!data) {
        return reply.status(400).send({ error: 'No file uploaded' });
      }

      try {
        const buffer = await data.toBuffer();
        const processor = new ExcelProcessor();
        const result = await processor.parseFile(buffer);

        if (result.success && result.data) {
          const validator = new MMRValidator();
          const validation = validator.validate(result.data);
          result.data.metadata.validation = validation;
        }

        return reply.send(result);
      } catch (err: any) {
        request.log.error(err);
        return reply.status(500).send({ error: 'Failed to parse MMR file', details: err.message });
      }
    });

    // 🔧 global error handler (no more empty replies)
    server.setErrorHandler((error, request, reply) => {
      server.log.error(error);
      reply.status(500).send({
        error: 'Internal Server Error',
        message: error.message,
      });
    });

    const port = parseInt(process.env.PORT || '8083');
    await server.listen({ port, host: '0.0.0.0' });

    server.log.info(`🚀 MMR Service running at http://localhost:${port}`);
  } catch (error) {
    server.log.error(error);
    process.exit(1);
  }
}

start();

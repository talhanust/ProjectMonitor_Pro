#!/bin/bash

echo "🔧 Installing custom MMR parser..."

# Add the custom parser to the worker
cat >> backend/services/mmr-service/src/workers/mmrWorker.ts << 'WORKER_APPEND'

// Import custom parser
import customMMRWorker from './customMMRWorker';

// Add method to use custom parser
async processProjectMMR(buffer: Buffer, job: Job): Promise<any> {
  return await customMMRWorker.processProjectMMR(buffer, job);
}
WORKER_APPEND

echo "✅ Custom parser added"
echo ""
echo "Restart the service to use the custom parser:"
echo "  1. Stop current service (Ctrl+C)"
echo "  2. Run: make dev"
echo ""
echo "Then run the test again with:"
echo "  ./process-real-mmr.sh"

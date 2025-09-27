#!/bin/bash
set -e

# Step 1: Fix Fastify logger type in backend
BACKEND_INDEX="backend/services/api/src/index.ts"
echo "Applying Fastify logger type fix in $BACKEND_INDEX..."

# Use sed to replace the logger line
sed -i.bak -E "s/^\s*logger\s*,/logger: logger as unknown as import('fastify').FastifyBaseLogger,/" "$BACKEND_INDEX"

echo "Logger type fix applied. Backup saved as index.ts.bak"

# Step 2: Build frontend
echo "Building frontend..."
cd frontend
npm install
npm run build
cd ..

# Step 3: Build backend
echo "Building backend..."
cd backend/services/api
npm install
npm run build
cd ../../..

echo "✅ Both frontend and backend built successfully!"

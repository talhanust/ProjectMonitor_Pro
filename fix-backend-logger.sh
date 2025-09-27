#!/bin/bash

API_DIR="./backend/services/api-gateway/src"

echo "🛠 Fixing Fastify logger type in src/index.ts..."

# Backup original file
cp "$API_DIR/index.ts" "$API_DIR/index.ts.bak"

# Replace logger initialization line
# Looks for `logger,` in fastify() call and casts it to FastifyBaseLogger
sed -i "s/logger,/logger as unknown as import('fastify').FastifyBaseLogger,/" "$API_DIR/index.ts"

echo "✅ Logger type fixed. Original file backed up as index.ts.bak"
echo "Now run: cd backend/services/api-gateway && npm run build"

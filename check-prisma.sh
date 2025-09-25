#!/bin/bash
set -e

SCHEMA="./backend/services/api/prisma/schema.prisma"
PRISMA_ENV="./backend/services/api/prisma/.env"

echo "🔹 Using Prisma schema: $SCHEMA"
echo "🔹 Using Prisma .env: $PRISMA_ENV"

# Export only Prisma env
export $(grep -v '^#' $PRISMA_ENV | xargs)

# Force Prisma to use only the specified .env
export PRISMA_DOTENV_PATH="$PRISMA_ENV"

# Check CLI version
npx prisma -v

# Validate schema
npx prisma validate --schema $SCHEMA

# Check database connection
npx prisma db pull --schema $SCHEMA

# Check migration status
npx prisma migrate status --schema $SCHEMA

# Generate client
npx prisma generate --schema $SCHEMA

echo "✅ Prisma checks complete. To open Studio: npx prisma studio --schema $SCHEMA"

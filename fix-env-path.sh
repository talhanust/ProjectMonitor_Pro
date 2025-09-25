#!/bin/bash

# Ensure DATABASE_URL is available for Prisma
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/project_monitor_pro?schema=public"

# Run migrations from the correct location
cd backend/services/api
npx prisma migrate deploy
cd ../../..

echo "✅ Migrations checked"

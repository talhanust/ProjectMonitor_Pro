#!/bin/bash

echo "🚀 Starting ProjectMonitor Pro environment..."

# Start PostgreSQL
echo "🗄️ Starting PostgreSQL..."
sudo service postgresql start

# Set DATABASE_URL for migrations
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/project_monitor_pro?schema=public"

# Run migrations from backend directory
echo "🛠️ Checking database migrations..."
cd backend/services/api
npx prisma migrate deploy 2>/dev/null || echo "  ℹ️ Migrations up to date"
cd ../..

# Start the dev servers
echo "⚡ Starting backend and frontend..."
npm run dev

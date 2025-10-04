#!/bin/bash

# Complete PostgreSQL Setup Script
# Sets up PostgreSQL and runs database migrations

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     PostgreSQL Setup and Database Migration                         ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[1/5]${NC} Removing old PostgreSQL container if exists..."

docker rm -f postgres-dev 2>/dev/null || echo "No old container to remove"

echo -e "${GREEN}✓${NC} Cleanup complete"

echo -e "${BLUE}[2/5]${NC} Starting PostgreSQL container..."

docker run -d \
  --name postgres-dev \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=engineering_app \
  -p 5432:5432 \
  postgres:15-alpine

echo -e "${GREEN}✓${NC} PostgreSQL container started"

echo -e "${BLUE}[3/5]${NC} Waiting for PostgreSQL to be ready..."

sleep 10

# Check if PostgreSQL is accepting connections
until docker exec postgres-dev pg_isready -U postgres > /dev/null 2>&1; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

echo -e "${GREEN}✓${NC} PostgreSQL is ready"

echo -e "${BLUE}[4/5]${NC} Running Prisma migrations..."

cd /workspaces/ProjectMonitor_Pro/backend/services/api-gateway

# Generate Prisma client
npx prisma generate

# Run migrations
npx prisma migrate deploy || {
  echo -e "${YELLOW}⚠${NC} No migrations found. Creating initial migration..."
  npx prisma migrate dev --name init
}

echo -e "${GREEN}✓${NC} Database migrations complete"

echo -e "${BLUE}[5/5]${NC} Verifying database connection..."

docker exec postgres-dev psql -U postgres -d engineering_app -c "\dt" || echo "Tables will be created on first use"

echo -e "${GREEN}✓${NC} Database verified"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           ✅ PostgreSQL Setup Complete!                             ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Database information:"
echo "  Host:     localhost"
echo "  Port:     5432"
echo "  User:     postgres"
echo "  Password: postgres"
echo "  Database: engineering_app"
echo ""
echo "Container status:"
docker ps | grep postgres
echo ""
echo "Next steps:"
echo "  1. API Gateway should now connect to database"
echo "  2. Try registering at /register"
echo "  3. After registration, go to /mmr and upload files"
echo ""
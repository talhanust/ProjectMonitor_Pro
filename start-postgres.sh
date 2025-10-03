#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Starting PostgreSQL with Docker            ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker is not running. Starting Docker...${NC}"
    sudo service docker start
    sleep 2
fi

# Stop any existing postgres container
docker stop postgres-dev 2>/dev/null || true
docker rm postgres-dev 2>/dev/null || true

echo -e "${GREEN}Starting PostgreSQL container...${NC}"
docker run -d \
  --name postgres-dev \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=engineering_app \
  -p 5432:5432 \
  postgres:15-alpine

echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
sleep 5

# Check if PostgreSQL is ready
if docker exec postgres-dev pg_isready -U postgres; then
    echo -e "${GREEN}✅ PostgreSQL is running!${NC}"
else
    echo -e "${RED}PostgreSQL failed to start. Checking logs...${NC}"
    docker logs postgres-dev
    exit 1
fi

echo ""
echo -e "${GREEN}Now pushing Prisma schema...${NC}"
cd backend/services/api-gateway
npx prisma db push

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    PostgreSQL and Prisma Ready!               ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Database is running at:${NC}"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: engineering_app"
echo "  User: postgres"
echo "  Password: postgres"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart the API Gateway:"
echo "     ${BLUE}cd backend/services/api-gateway && npm run dev${NC}"
echo ""
echo "  2. Test authentication:"
echo "     ${BLUE}./backend/services/api-gateway/test-db-auth.sh${NC}"

cd ../../..

#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Complete Database Setup & Fix              ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Step 1: Ensure .env exists in the shared directory
echo -e "${GREEN}Creating .env file in shared directory...${NC}"
cat > backend/services/shared/.env << 'ENV'
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app
ENV

# Step 2: Check if Docker is running
echo -e "${GREEN}Checking Docker status...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker is not running. Starting Docker...${NC}"
    sudo service docker start
    sleep 3
fi

# Step 3: Start PostgreSQL
echo -e "${GREEN}Starting PostgreSQL container...${NC}"
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
for i in {1..10}; do
    if docker exec engineering_postgres pg_isready -U postgres > /dev/null 2>&1; then
        echo -e "${GREEN}PostgreSQL is ready!${NC}"
        break
    fi
    echo "Waiting... ($i/10)"
    sleep 2
done

# Step 4: Run migrations
cd backend/services/shared

echo -e "${GREEN}Running Prisma migrations...${NC}"
npx prisma migrate dev --name initial

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Migrations successful!${NC}"
    
    echo -e "${GREEN}Seeding database...${NC}"
    npm run prisma:seed
    
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}    Database Setup Complete!                   ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo -e "${GREEN}Services running:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    echo -e "${YELLOW}Test users:${NC}"
    echo "  admin@example.com / Admin123!"
    echo "  john.doe@example.com / User123!"
    echo "  jane.smith@example.com / User123!"
    echo ""
    echo -e "${YELLOW}Access points:${NC}"
    echo "  Prisma Studio: ${BLUE}npx prisma studio${NC}"
    echo "  Adminer: ${BLUE}http://localhost:8090${NC}"
    echo "  PostgreSQL: ${BLUE}localhost:5432${NC}"
else
    echo -e "${RED}Migration failed!${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check PostgreSQL logs:"
    echo "   ${BLUE}docker logs engineering_postgres${NC}"
    echo ""
    echo "2. Test connection manually:"
    echo "   ${BLUE}docker exec -it engineering_postgres psql -U postgres -c '\\l'${NC}"
    echo ""
    echo "3. Recreate database:"
    echo "   ${BLUE}docker-compose down -v${NC}"
    echo "   ${BLUE}docker-compose up -d postgres${NC}"
fi

cd ../../..

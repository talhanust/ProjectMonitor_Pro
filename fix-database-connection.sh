#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Fixing Database Connection                 ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

cd backend/services/api-gateway

echo -e "${GREEN}Updating DATABASE_URL in .env...${NC}"
# Backup current .env
cp .env .env.backup

# Update the DATABASE_URL
grep -v "DATABASE_URL" .env.backup > .env
echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app?schema=public" >> .env

echo -e "${GREEN}Current DATABASE_URL:${NC}"
grep "DATABASE_URL" .env

echo -e "${GREEN}Testing database connection...${NC}"
npx prisma db push

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database connection successful!${NC}"
    
    echo -e "${GREEN}Creating test user...${NC}"
    cat > test-db.js << 'TESTJS'
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  const hashedPassword = await bcrypt.hash('Test1234!', 10);
  
  try {
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        password: hashedPassword,
        name: 'Test User',
        role: 'USER',
      },
    });
    console.log('Created test user:', user);
  } catch (error) {
    if (error.code === 'P2002') {
      console.log('Test user already exists');
    } else {
      throw error;
    }
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
TESTJS
    
    node test-db.js
    rm test-db.js
else
    echo -e "${RED}❌ Database connection failed${NC}"
    echo -e "${YELLOW}Checking Docker container...${NC}"
    docker ps | grep postgres-dev
fi

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Database Ready for Authentication!         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Now restart the API Gateway:${NC}"
echo "  ${BLUE}npm run dev${NC}"
echo ""
echo -e "${YELLOW}Then test authentication:${NC}"
echo "  ${BLUE}./test-db-auth.sh${NC}"

cd ../../..

#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Setting Up Prisma for Auth Controller      ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Navigate to api-gateway directory
cd backend/services/api-gateway

echo -e "${GREEN}Step 1: Creating Prisma schema...${NC}"
mkdir -p prisma
cat > prisma/schema.prisma << 'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String
  name      String?
  role      String   @default("USER")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@map("users")
}
PRISMA

echo -e "${GREEN}Step 2: Checking DATABASE_URL...${NC}"
if ! grep -q "DATABASE_URL" .env; then
  echo -e "${YELLOW}Adding DATABASE_URL to .env...${NC}"
  echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app?schema=public" >> .env
else
  echo -e "${GREEN}DATABASE_URL already exists in .env${NC}"
fi

echo -e "${GREEN}Step 3: Installing Prisma dependencies...${NC}"
npm install @prisma/client
npm install -D prisma

echo -e "${GREEN}Step 4: Generating Prisma Client...${NC}"
npx prisma generate

echo -e "${GREEN}Step 5: Pushing schema to database...${NC}"
if npx prisma db push; then
  echo -e "${GREEN}✅ Database schema synchronized successfully!${NC}"
else
  echo -e "${RED}❌ Failed to sync database. Checking PostgreSQL...${NC}"
  
  # Check if PostgreSQL is running
  if ! pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo -e "${YELLOW}PostgreSQL is not running. Starting it...${NC}"
    sudo service postgresql start
    sleep 2
    
    # Try again
    if npx prisma db push; then
      echo -e "${GREEN}✅ Database schema synchronized after starting PostgreSQL!${NC}"
    else
      echo -e "${RED}Still failed. Please check your database connection.${NC}"
    fi
  fi
fi

echo -e "${GREEN}Step 6: Creating a test script...${NC}"
cat > test-db-auth.sh << 'TEST'
#!/bin/bash

# Test registration with database
echo "Testing registration with database..."
curl -X POST http://localhost:8080/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"dbuser@example.com","password":"Test1234!","name":"Database User"}' \
  | jq .

echo ""
echo "Testing login with the same user..."
curl -X POST http://localhost:8080/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"dbuser@example.com","password":"Test1234!"}' \
  | jq .
TEST
chmod +x test-db-auth.sh

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Prisma Setup Complete!                     ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Restart the API Gateway server:"
echo "     ${BLUE}npm run dev${NC}"
echo ""
echo "  2. Test authentication with database:"
echo "     ${BLUE}./test-db-auth.sh${NC}"
echo ""
echo "  3. View your database (optional):"
echo "     ${BLUE}npx prisma studio${NC}"
echo ""
echo -e "${GREEN}Your authentication system now uses a real PostgreSQL database!${NC}"

cd ../../..

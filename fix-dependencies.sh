#!/bin/bash

################################################################################
# Fix Dependencies Script
# Fixes the "Cannot find module 'bull'" issue
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Fixing MMR Service Dependencies${NC}"
echo ""

cd /workspaces/ProjectMonitor_Pro/backend/services/mmr-service

echo -e "${CYAN}[1/5] Removing old dependencies...${NC}"
rm -rf node_modules package-lock.json
echo -e "${GREEN}✓ Cleaned${NC}"

echo -e "${CYAN}[2/5] Updating package.json...${NC}"
cat > package.json << 'EOF'
{
  "name": "mmr-service",
  "version": "1.0.0",
  "description": "MMR Queue Service with Excel Support",
  "main": "dist/index.js",
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "bull": "^4.11.5",
    "ioredis": "^5.3.2",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5",
    "helmet": "^7.1.0",
    "compression": "^1.7.4",
    "express-validator": "^7.0.1",
    "uuid": "^9.0.1",
    "xlsx": "^0.18.5",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.6",
    "@types/cors": "^2.8.17",
    "@types/compression": "^1.7.5",
    "@types/uuid": "^9.0.7",
    "@types/bull": "^4.10.0",
    "typescript": "^5.3.3",
    "ts-node-dev": "^2.0.0"
  }
}
EOF
echo -e "${GREEN}✓ package.json updated${NC}"

echo -e "${CYAN}[3/5] Updating tsconfig.json...${NC}"
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "rootDir": "../../",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "sourceMap": true,
    "declaration": false
  },
  "include": ["src/**/*", "../shared/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
echo -e "${GREEN}✓ tsconfig.json updated${NC}"

echo -e "${CYAN}[4/5] Installing dependencies (this may take a minute)...${NC}"
npm install
echo -e "${GREEN}✓ Dependencies installed${NC}"

echo -e "${CYAN}[5/5] Verifying installation...${NC}"
if [ -d "node_modules/bull" ]; then
    echo -e "${GREEN}✓ bull installed${NC}"
else
    echo -e "${RED}✗ bull not found, installing explicitly...${NC}"
    npm install bull@4.11.5 --save
fi

if [ -d "node_modules/ioredis" ]; then
    echo -e "${GREEN}✓ ioredis installed${NC}"
else
    echo -e "${RED}✗ ioredis not found, installing explicitly...${NC}"
    npm install ioredis@5.3.2 --save
fi

if [ -d "node_modules/xlsx" ]; then
    echo -e "${GREEN}✓ xlsx installed${NC}"
else
    echo -e "${RED}✗ xlsx not found, installing explicitly...${NC}"
    npm install xlsx@0.18.5 --save
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                      ║${NC}"
echo -e "${GREEN}║                  ✅ Dependencies Fixed!                             ║${NC}"
echo -e "${GREEN}║                                                                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo -e "  ${BLUE}cd /workspaces/ProjectMonitor_Pro${NC}"
echo -e "  ${BLUE}make dev${NC}"
echo ""
echo -e "${YELLOW}Note: If you still get errors, try:${NC}"
echo -e "  ${BLUE}cd backend/services/mmr-service${NC}"
echo -e "  ${BLUE}npm run dev${NC}"
echo ""
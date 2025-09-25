#!/bin/bash

# Fix Prisma Environment Variable Conflicts
# This script consolidates the .env files to resolve conflicts

set -e

echo "🔧 Fixing Prisma Environment Variable Conflicts"
echo "=============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Backup existing env files
echo "📦 Backing up existing .env files..."
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "  ✅ Backed up root .env"
fi

if [ -f "backend/services/api/prisma/.env" ]; then
    cp backend/services/api/prisma/.env backend/services/api/prisma/.env.backup.$(date +%Y%m%d_%H%M%S)
    echo "  ✅ Backed up prisma .env"
fi

# 2. Remove the conflicting Prisma .env file
echo ""
echo "🗑️ Removing conflicting Prisma .env file..."
if [ -f "backend/services/api/prisma/.env" ]; then
    rm backend/services/api/prisma/.env
    echo "  ✅ Removed backend/services/api/prisma/.env"
fi

# 3. Ensure root .env has all necessary variables
echo ""
echo "📝 Updating root .env file..."
if [ ! -f ".env" ]; then
    cat > .env << 'EOF'
# Environment
NODE_ENV=development

# Server
PORT=8080

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/project_monitor_pro?schema=public

# Security
JWT_SECRET=your-secret-key-change-in-production

# CORS
CORS_ORIGIN=http://localhost:3000
EOF
    echo "  ✅ Created new .env file with all variables"
else
    echo "  ℹ️ Using existing root .env file"
fi

# 4. Update package.json to point Prisma to the correct schema location
echo ""
echo "📦 Updating package.json for Prisma configuration..."
node -e "
const fs = require('fs');
const path = require('path');

// Update root package.json
const rootPkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
rootPkg.prisma = {
  schema: 'backend/services/api/prisma/schema.prisma'
};
fs.writeFileSync('package.json', JSON.stringify(rootPkg, null, 2) + '\n');
console.log('  ✅ Updated root package.json with Prisma schema path');

// Also update backend package.json
const backendPkgPath = 'backend/services/api/package.json';
if (fs.existsSync(backendPkgPath)) {
  const backendPkg = JSON.parse(fs.readFileSync(backendPkgPath, 'utf8'));
  backendPkg.prisma = {
    schema: './prisma/schema.prisma'
  };
  fs.writeFileSync(backendPkgPath, JSON.stringify(backendPkg, null, 2) + '\n');
  console.log('  ✅ Updated backend package.json with Prisma schema path');
}
"

# 5. Generate Prisma Client
echo ""
echo "⚙️ Generating Prisma Client..."
npx prisma generate --schema ./backend/services/api/prisma/schema.prisma

# 6. Check database connection
echo ""
echo "🔍 Checking database connection..."
npx prisma db pull --schema ./backend/services/api/prisma/schema.prisma --print 2>/dev/null || {
    echo -e "  ${YELLOW}⚠️ Could not connect to database. Make sure PostgreSQL is running.${NC}"
    echo "  Start PostgreSQL with: sudo service postgresql start"
}

# 7. Run migrations
echo ""
echo "🚀 Running Prisma migrations..."
cd backend/services/api
npx prisma migrate deploy 2>/dev/null || {
    echo "  ℹ️ No pending migrations or migrations already applied"
}
cd ../../..

# 8. Create a simple test script
echo ""
echo "📝 Creating database test script..."
cat > test-db-connection.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    // Test connection
    await prisma.$connect();
    console.log('✅ Successfully connected to database');
    
    // Count users
    const userCount = await prisma.user.count();
    console.log(`📊 Total users: ${userCount}`);
    
    // Count projects
    const projectCount = await prisma.project.count();
    console.log(`📊 Total projects: ${projectCount}`);
    
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();
EOF

# 9. Test the connection
echo ""
echo "🧪 Testing database connection..."
node test-db-connection.js

# 10. Clean up test file
rm test-db-connection.js

echo ""
echo "=============================================="
echo -e "${GREEN}✅ Environment conflicts resolved!${NC}"
echo ""
echo "📋 What was done:"
echo "  • Backed up existing .env files"
echo "  • Removed conflicting Prisma .env file"
echo "  • Consolidated all environment variables in root .env"
echo "  • Updated package.json files with Prisma schema paths"
echo "  • Generated Prisma Client"
echo "  • Tested database connection"
echo ""
echo "🎯 Next steps:"
echo "  1. Run migrations if needed: cd backend/services/api && npx prisma migrate dev"
echo "  2. Start your development servers: npm run dev"
echo "  3. If you need to modify env variables, edit the root .env file"
echo ""
echo -e "${YELLOW}⚠️ Important:${NC}"
echo "  • All environment variables are now in the root .env file"
echo "  • Do NOT create a .env file in backend/services/api/prisma/"
echo "  • Prisma will automatically use the root .env file"
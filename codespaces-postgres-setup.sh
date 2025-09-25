#!/bin/bash

# GitHub Codespaces PostgreSQL Setup Script
# No sudo password required - runs with codespace user privileges

set -e

echo "🚀 GitHub Codespaces PostgreSQL Setup"
echo "======================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Check if PostgreSQL is installed
echo "📦 Checking PostgreSQL installation..."
if ! command -v psql &> /dev/null; then
    echo "  Installing PostgreSQL..."
    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib
    echo "  ✅ PostgreSQL installed"
else
    echo "  ✅ PostgreSQL already installed"
fi

# 2. Start PostgreSQL service
echo ""
echo "🔧 Starting PostgreSQL service..."
sudo service postgresql start
echo "  ✅ PostgreSQL service started"

# 3. Setup PostgreSQL user and database
echo ""
echo "📝 Setting up PostgreSQL database..."

# Create the database setup
sudo -u postgres psql << 'EOSQL'
-- Create user if not exists
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_user
      WHERE usename = 'postgres') THEN
      CREATE USER postgres WITH PASSWORD 'postgres';
   END IF;
END
$do$;

-- Set password for postgres user
ALTER USER postgres PASSWORD 'postgres';

-- Give postgres user necessary permissions
ALTER USER postgres CREATEDB;
ALTER USER postgres WITH SUPERUSER;

-- Create database if not exists
SELECT 'CREATE DATABASE project_monitor_pro'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'project_monitor_pro')\gexec

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE project_monitor_pro TO postgres;

-- Connect to the database and create schema if needed
\c project_monitor_pro
CREATE SCHEMA IF NOT EXISTS public;
GRANT ALL ON SCHEMA public TO postgres;

-- Show confirmation
\echo '✅ Database setup complete'
EOSQL

# 4. Update .env file with correct database URL
echo ""
echo "📝 Updating .env file..."
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

# Additional settings for Codespaces
HOSTNAME=0.0.0.0
EOF
echo "  ✅ .env file updated"

# 5. Create prisma.config.ts (new recommended approach)
echo ""
echo "📝 Creating Prisma configuration..."
cat > prisma.config.ts << 'EOF'
export default {
  schema: './backend/services/api/prisma/schema.prisma',
  dotenvPath: './.env'
}
EOF
echo "  ✅ prisma.config.ts created"

# 6. Test database connection
echo ""
echo "🧪 Testing database connection..."
PGPASSWORD=postgres psql -h localhost -U postgres -d project_monitor_pro -c '\q' 2>/dev/null && {
    echo "  ✅ Database connection successful!"
} || {
    echo "  ❌ Database connection failed"
    echo "  Trying alternative connection method..."
    
    # Try with peer authentication
    sudo -u postgres psql -d project_monitor_pro -c '\q' 2>/dev/null && {
        echo "  ✅ Connected using peer authentication"
    } || {
        echo "  ❌ Could not connect to database"
        exit 1
    }
}

# 7. Generate Prisma Client
echo ""
echo "⚙️ Generating Prisma Client..."
npx prisma generate --schema ./backend/services/api/prisma/schema.prisma || {
    echo "  ⚠️ Prisma generate failed, trying to fix..."
    npm install @prisma/client prisma
    npx prisma generate --schema ./backend/services/api/prisma/schema.prisma
}

# 8. Run Prisma migrations
echo ""
echo "🚀 Running Prisma migrations..."
npx prisma migrate deploy --schema ./backend/services/api/prisma/schema.prisma 2>/dev/null || {
    echo "  ℹ️ No pending migrations or creating new migration..."
    npx prisma migrate dev --schema ./backend/services/api/prisma/schema.prisma --name init || {
        echo "  ⚠️ Migration failed, attempting reset..."
        echo "  This will drop all data in the database!"
        read -p "  Continue with reset? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            npx prisma migrate reset --schema ./backend/services/api/prisma/schema.prisma --force
            npx prisma migrate dev --schema ./backend/services/api/prisma/schema.prisma --name init
        fi
    }
}

# 9. Seed database with initial data
echo ""
echo "🌱 Creating seed data..."
cat > seed-database.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    // Create default user
    const user = await prisma.user.upsert({
      where: { email: 'admin@example.com' },
      update: {},
      create: {
        email: 'admin@example.com',
        name: 'Admin User',
      }
    });
    console.log('  ✅ Created admin user:', user.email);

    // Create sample project
    const project = await prisma.project.upsert({
      where: { id: 1 },
      update: {},
      create: {
        name: 'Sample Project',
        description: 'This is a sample project for testing',
        status: 'active',
        ownerId: user.id,
      }
    });
    console.log('  ✅ Created sample project:', project.name);

  } catch (error) {
    console.error('  ❌ Seeding failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();
EOF

node seed-database.js
rm seed-database.js

# 10. Create helper scripts
echo ""
echo "📝 Creating helper scripts..."

# Create db-status script
cat > check-db.sh << 'EOF'
#!/bin/bash
echo "Checking database status..."
sudo service postgresql status
PGPASSWORD=postgres psql -h localhost -U postgres -d project_monitor_pro -c '\dt' 2>/dev/null && echo "✅ Database connected" || echo "❌ Database not accessible"
EOF
chmod +x check-db.sh

# Create studio script
cat > studio.sh << 'EOF'
#!/bin/bash
npx prisma studio --schema ./backend/services/api/prisma/schema.prisma --port 5555
EOF
chmod +x studio.sh

# 11. Final summary
echo ""
echo "======================================"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo ""
echo "📋 What was configured:"
echo "  • PostgreSQL installed and running"
echo "  • Database: project_monitor_pro"
echo "  • User: postgres (password: postgres)"
echo "  • Prisma Client generated"
echo "  • Migrations applied"
echo "  • Sample data seeded"
echo ""
echo "🎯 Quick commands:"
echo "  ./check-db.sh    - Check database status"
echo "  ./studio.sh      - Open Prisma Studio"
echo "  npm run dev      - Start development servers"
echo ""
echo "📝 Database URL for reference:"
echo "  postgresql://postgres:postgres@localhost:5432/project_monitor_pro"
echo ""
echo "⚠️ Note: PostgreSQL will need to be restarted if you stop/restart the Codespace:"
echo "  sudo service postgresql start"
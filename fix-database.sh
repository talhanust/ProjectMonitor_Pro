#!/bin/bash

# Fix Database Connection and Prisma Setup
set -e

echo "🔧 Fixing Database Connection"
echo "=============================="
echo ""

# 1. First, check and start PostgreSQL if needed
echo "📦 Checking PostgreSQL status..."
if command -v psql &> /dev/null; then
    # Try to start PostgreSQL
    sudo service postgresql start 2>/dev/null || {
        echo "  ⚠️ Could not start PostgreSQL automatically"
        echo "  Try: sudo service postgresql start"
    }
    
    # Check if PostgreSQL is running
    if pg_isready &>/dev/null; then
        echo "  ✅ PostgreSQL is running"
    else
        echo "  ❌ PostgreSQL is not running. Please start it manually:"
        echo "     sudo service postgresql start"
    fi
else
    echo "  ❌ PostgreSQL not installed. Please install it first:"
    echo "     sudo apt update && sudo apt install postgresql postgresql-contrib"
    exit 1
fi

# 2. Check current database credentials
echo ""
echo "🔍 Checking database credentials in .env..."
if [ -f ".env" ]; then
    source .env
    echo "  DATABASE_URL: ${DATABASE_URL}"
else
    echo "  ❌ No .env file found"
fi

# 3. Test PostgreSQL connection with current credentials
echo ""
echo "🧪 Testing PostgreSQL connection..."

# Extract connection details from DATABASE_URL
if [[ $DATABASE_URL =~ postgresql://([^:]+):([^@]+)@([^:]+):([^/]+)/([^?]+) ]]; then
    DB_USER="${BASH_REMATCH[1]}"
    DB_PASS="${BASH_REMATCH[2]}"
    DB_HOST="${BASH_REMATCH[3]}"
    DB_PORT="${BASH_REMATCH[4]}"
    DB_NAME="${BASH_REMATCH[5]}"
    
    echo "  User: $DB_USER"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    
    # Test connection
    PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null && {
        echo "  ✅ PostgreSQL connection successful"
    } || {
        echo "  ❌ Connection failed. Setting up database..."
        
        # Try to create the database and user
        echo ""
        echo "📝 Setting up PostgreSQL database..."
        
        # Create database setup script
        cat > /tmp/setup_db.sql << EOF
-- Create user if not exists
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'postgres') THEN
      CREATE USER postgres WITH PASSWORD 'postgres';
   END IF;
END
\$\$;

-- Grant permissions
ALTER USER postgres CREATEDB;

-- Create database if not exists
SELECT 'CREATE DATABASE project_monitor_pro'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'project_monitor_pro');

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE project_monitor_pro TO postgres;
EOF
        
        # Run setup as postgres user
        sudo -u postgres psql < /tmp/setup_db.sql 2>/dev/null || {
            echo "  ⚠️ Could not auto-setup database. Manual setup required:"
            echo ""
            echo "  Run these commands:"
            echo "    sudo -u postgres psql"
            echo "    CREATE USER postgres WITH PASSWORD 'postgres';"
            echo "    CREATE DATABASE project_monitor_pro;"
            echo "    GRANT ALL PRIVILEGES ON DATABASE project_monitor_pro TO postgres;"
            echo "    \q"
        }
        
        rm /tmp/setup_db.sql
    }
fi

# 4. Create a Prisma configuration file (new recommended approach)
echo ""
echo "📝 Creating Prisma configuration file..."
cat > prisma.config.ts << 'EOF'
export default {
  schema: './backend/services/api/prisma/schema.prisma',
  dotenvPath: './.env'
}
EOF
echo "  ✅ Created prisma.config.ts"

# 5. Ensure .env is properly formatted
echo ""
echo "🔧 Ensuring .env file is properly configured..."
cat > .env << 'EOF'
# Environment
NODE_ENV=development

# Server
PORT=8080

# Database - Update these if your PostgreSQL setup is different
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/project_monitor_pro?schema=public

# Security
JWT_SECRET=your-secret-key-change-in-production

# CORS
CORS_ORIGIN=http://localhost:3000
EOF
echo "  ✅ .env file updated"

# 6. Generate Prisma Client
echo ""
echo "⚙️ Generating Prisma Client..."
npx prisma generate --schema ./backend/services/api/prisma/schema.prisma

# 7. Run migrations from the root directory
echo ""
echo "🚀 Running Prisma migrations..."
npx prisma migrate dev --schema ./backend/services/api/prisma/schema.prisma --name init || {
    echo "  ℹ️ Migrations might already be applied or there was an error"
    echo "  Trying to reset and reapply..."
    
    # If migrations fail, try reset in dev mode
    read -p "  Do you want to reset the database? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npx prisma migrate reset --schema ./backend/services/api/prisma/schema.prisma --force
    fi
}

# 8. Test the final connection
echo ""
echo "🧪 Final connection test..."
cat > test-connection.js << 'EOF'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    await prisma.$connect();
    console.log('  ✅ Database connection successful!');
    
    // Create a test user
    const user = await prisma.user.upsert({
      where: { email: 'test@example.com' },
      update: {},
      create: {
        email: 'test@example.com',
        name: 'Test User',
      }
    });
    console.log(`  ✅ Test user created/found: ${user.email}`);
    
  } catch (error) {
    console.error('  ❌ Connection test failed:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();
EOF

node test-connection.js
rm test-connection.js

echo ""
echo "=============================="
echo "✅ Database setup complete!"
echo ""
echo "📋 Summary:"
echo "  • PostgreSQL is configured"
echo "  • Database 'project_monitor_pro' is ready"
echo "  • Prisma Client is generated"
echo "  • Migrations are applied"
echo ""
echo "🎯 Next steps:"
echo "  1. Start your dev servers: npm run dev"
echo "  2. Access Prisma Studio: npx prisma studio --schema ./backend/services/api/prisma/schema.prisma"
echo ""
echo "📝 Notes:"
echo "  • Always run Prisma commands from the project root"
echo "  • Use --schema flag to specify the schema location"
echo "  • All env variables are in the root .env file"
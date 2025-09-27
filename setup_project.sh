#!/bin/bash
set -e

echo "🚀 Starting monorepo project setup..."

# ----------------------------
# Configuration
# ----------------------------
POSTGRES_CONTAINER="project_monitor_db"
POSTGRES_IMAGE="postgres:15"
POSTGRES_PORT="5432"
POSTGRES_USER="user"
POSTGRES_PASSWORD="password"
POSTGRES_DB="engineering_app"
NODE_VERSION="20"

# Backend & Prisma paths
BACKEND_DIR="backend/services/api"
PRISMA_DIR="$BACKEND_DIR/prisma"
PRISMA_SCHEMA="$PRISMA_DIR/schema.prisma"

# ----------------------------
# Step 0: Ensure Git repo exists
# ----------------------------
if [ ! -d ".git" ]; then
    echo "⚠️ .git folder not found. Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
    echo "✅ Git repository initialized."
fi

# ----------------------------
# Step 1: Verify backend folder
# ----------------------------
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Backend folder not found at $BACKEND_DIR"
    exit 1
fi
echo "✅ Backend workspace detected at $BACKEND_DIR"

# Ensure Prisma folder exists
mkdir -p "$PRISMA_DIR"
echo "✅ Prisma folder ready at $PRISMA_DIR"

# ----------------------------
# Step 2: Load nvm and switch Node version
# ----------------------------
export NVM_DIR="/usr/local/share/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "🔧 Using Node version $NODE_VERSION..."
nvm install $NODE_VERSION
nvm use $NODE_VERSION
echo "Node version: $(node -v)"

# ----------------------------
# Step 3: Start PostgreSQL container if not running
# ----------------------------
if [ "$(docker ps -q -f name=$POSTGRES_CONTAINER)" ]; then
    echo "🐳 PostgreSQL container already running."
else
    echo "🐳 Starting PostgreSQL container..."
    docker-compose up -d
    sleep 10
fi

# ----------------------------
# Step 4: Create PostgreSQL user and database safely
# ----------------------------
echo "🛠 Creating PostgreSQL user and database..."
USER_EXISTS=$(docker exec -i $POSTGRES_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'")
if [ "$USER_EXISTS" != "1" ]; then
    docker exec -i $POSTGRES_CONTAINER psql -U postgres -c "CREATE USER \"$POSTGRES_USER\" WITH PASSWORD '$POSTGRES_PASSWORD';"
    echo "✅ User $POSTGRES_USER created."
else
    echo "✅ User $POSTGRES_USER already exists."
fi

docker exec -i $POSTGRES_CONTAINER psql -U postgres -c "ALTER USER \"$POSTGRES_USER\" CREATEDB;"
echo "✅ Granted CREATEDB permission to $POSTGRES_USER."

DB_EXISTS=$(docker exec -i $POSTGRES_CONTAINER psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$POSTGRES_DB'")
if [ "$DB_EXISTS" != "1" ]; then
    docker exec -i $POSTGRES_CONTAINER psql -U postgres -c "CREATE DATABASE $POSTGRES_DB OWNER \"$POSTGRES_USER\";"
    echo "✅ Database $POSTGRES_DB created."
else
    echo "✅ Database $POSTGRES_DB already exists."
fi

# ----------------------------
# Step 5: Ensure .env file exists
# ----------------------------
if [ ! -f ".env" ]; then
  echo "⚠️ .env file not found. Creating from template..."
  cat <<ENV > .env
NODE_ENV=development
PORT=8080
DATABASE_URL=postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@localhost:$POSTGRES_PORT/$POSTGRES_DB
JWT_SECRET=your-secret-key-change-in-production
CORS_ORIGIN=http://localhost:3000
POSTGRES_USER=$POSTGRES_USER
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=$POSTGRES_DB
ENV
else
  echo "✅ .env file exists, using current values."
fi

# Load environment variables
export $(grep -v '^#' .env | xargs)

# ----------------------------
# Step 6: Install backend dependencies
# ----------------------------
echo "📦 Installing backend dependencies in $BACKEND_DIR..."
cd $BACKEND_DIR
rm -rf node_modules package-lock.json
npm install || echo "⚠️ npm install encountered errors, continuing..."

# ----------------------------
# Step 6b: Install Husky safely
# ----------------------------
if [ ! -d ".husky" ]; then
    echo "🔧 Installing Husky..."
    npm install husky --save-dev
    npx husky install || echo "⚠️ Husky install failed, continuing..."
fi

# ----------------------------
# Step 7: Create Prisma schema if missing
# ----------------------------
mkdir -p "$(dirname "$PRISMA_SCHEMA")"
if [ ! -f "$PRISMA_SCHEMA" ]; then
    echo "⚠️ Prisma schema not found. Creating basic schema..."
    cat <<EOL > "$PRISMA_SCHEMA"
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  name      String
  email     String   @unique
  createdAt DateTime @default(now())
}
EOL
fi
echo "✅ Prisma schema ready at $PRISMA_SCHEMA"

# ----------------------------
# Step 8: Pull database and generate Prisma client
# ----------------------------
cd "$PRISMA_DIR"
echo "🔧 Pulling database schema and generating Prisma client..."
npx prisma db pull 2>/dev/null && echo "✅ Database introspection successful." || echo "⚠️ Database empty, using existing schema.prisma"
npx prisma generate

# ----------------------------
# Step 9: Run Prisma migrations
# ----------------------------
echo "🚀 Running Prisma migrations..."
npx prisma migrate dev --name init

# ----------------------------
# Done
# ----------------------------
echo "🎉 Monorepo setup complete! PostgreSQL, Node, and Prisma are ready."

#!/bin/bash

echo "🚀 PostgreSQL Setup for Codespaces (No Password)"
echo "================================================"

# Start PostgreSQL
sudo service postgresql start

# Configure PostgreSQL without password prompts
sudo su - postgres << 'PSQL_CMDS'
psql << SQL
CREATE USER postgres WITH PASSWORD 'postgres';
ALTER USER postgres CREATEDB;
ALTER USER postgres WITH SUPERUSER;
CREATE DATABASE project_monitor_pro;
GRANT ALL PRIVILEGES ON DATABASE project_monitor_pro TO postgres;
\q
SQL
exit
PSQL_CMDS

# Update .env
cat > .env << 'ENV'
NODE_ENV=development
PORT=8080
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/project_monitor_pro?schema=public
JWT_SECRET=your-secret-key-change-in-production
CORS_ORIGIN=http://localhost:3000
ENV

# Test connection
export PGPASSWORD=postgres
psql -h localhost -U postgres -d project_monitor_pro -c '\q' && echo "✅ Database ready!"

# Generate Prisma Client and run migrations
npx prisma generate --schema ./backend/services/api/prisma/schema.prisma
npx prisma migrate dev --schema ./backend/services/api/prisma/schema.prisma --name init

echo "✅ Setup complete!"

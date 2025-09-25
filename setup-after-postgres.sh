#!/bin/bash

echo "Setting up database after PostgreSQL installation..."

# Start PostgreSQL
sudo service postgresql start

# Create database and user
sudo -u postgres psql << SQL
ALTER USER postgres PASSWORD 'postgres';
CREATE DATABASE IF NOT EXISTS project_monitor_pro;
GRANT ALL PRIVILEGES ON DATABASE project_monitor_pro TO postgres;
SQL

# Generate Prisma client
npx prisma generate --schema ./backend/services/api/prisma/schema.prisma

# Run migrations
npx prisma migrate dev --schema ./backend/services/api/prisma/schema.prisma --name init

echo "✅ Database setup complete!"

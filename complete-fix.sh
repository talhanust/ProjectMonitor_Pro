#!/bin/bash

# Function to free a port
free_port() {
  local PORT=$1
  PID=$(lsof -ti tcp:$PORT)
  if [ -n "$PID" ]; then
    echo "Port $PORT is in use by PID $PID, killing process..."
    kill -9 $PID
    sleep 1
  fi
}

# Free common ports
free_port 3000
free_port 3001
free_port 8080

# Start PostgreSQL in Docker
echo "Starting PostgreSQL in Docker..."
if [ "$(docker ps -q -f name=projectmonitor-db)" ]; then
    echo "PostgreSQL container already running"
else
    docker run --name projectmonitor-db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
fi

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
sleep 5

# Ensure database exists
echo "Ensuring database exists..."
docker exec -i projectmonitor-db psql -U postgres -c "CREATE DATABASE projectmonitor;" 2>/dev/null || true

# Run Prisma migrations
echo "Running Prisma migrations..."
cd /workspaces/ProjectMonitor_Pro/backend/services/api || exit
npx prisma migrate dev --name init

# Start backend
echo "Starting backend..."
npm run dev -w @backend/api &

# Start frontend
echo "Starting frontend..."
npm run dev -w frontend &

echo "✅ All services started!"
echo "Frontend: http://localhost:3000 (or next available port if 3000 is busy)"
echo "Backend: http://localhost:8080"

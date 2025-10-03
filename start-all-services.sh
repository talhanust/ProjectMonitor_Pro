#!/bin/bash

echo "Starting Project Monitor Pro services..."

# Start PostgreSQL if using Docker
echo "Starting database..."
docker-compose up -d postgres minio

# Wait for services to be ready
sleep 5

# Start backend services
echo "Starting backend services..."
(cd backend/services/api-gateway && npm run dev) &
(cd backend/services/project-service && npm run dev) &
(cd backend/services/document-service && npm run dev) &
(cd backend/services/mmr-service && npm run dev) &

# Start frontend
echo "Starting frontend..."
(cd frontend && npm run dev) &

echo ""
echo "All services starting up..."
echo ""
echo "Services will be available at:"
echo "  Frontend:        http://localhost:3000"
echo "  API Gateway:     http://localhost:8080"
echo "  Project Service: http://localhost:8081"
echo "  Document Service: http://localhost:8082"
echo "  MMR Service:     http://localhost:8083"
echo "  MinIO Console:   http://localhost:9001"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for user to stop
wait

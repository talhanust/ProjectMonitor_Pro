.PHONY: help install start stop dev health

help:
	@echo "MMR Queue System - Available Commands:"
	@echo "  make install    - Install dependencies"
	@echo "  make start      - Start Redis"
	@echo "  make stop       - Stop Redis"
	@echo "  make dev        - Start in development mode"
	@echo "  make health     - Check service health"
	@echo "  make test       - Generate and test Excel file"

install:
	@echo "Installing dependencies..."
	@cd backend/services/mmr-service && npm install

start:
	@echo "Starting Redis..."
	@docker-compose up -d redis
	@sleep 3
	@docker-compose exec redis redis-cli ping
	@echo "✓ Redis started"

stop:
	@docker-compose down

dev:
	@cd backend/services/mmr-service && npm run dev

health:
	@curl -s http://localhost:3001/health | jq || echo "Service not running"

test:
	@node scripts/generate-test-mmr.js 50 test-mmr.xlsx
	@echo "Test file created: test-mmr.xlsx"

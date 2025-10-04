#!/bin/bash

# Fix API Gateway Port Configuration
# Updates frontend to use correct API Gateway port (8080)

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     Fix API Gateway Port Configuration                              ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Updating .env.local to use port 8080..."

# Update API URL to use port 8080
sed -i 's|NEXT_PUBLIC_API_URL=http://localhost:8081|NEXT_PUBLIC_API_URL=http://localhost:8080|g' .env.local

# Verify the change
echo ""
echo "Updated configuration:"
grep "NEXT_PUBLIC_API_URL\|NEXT_PUBLIC_DOCUMENT_API_URL\|NEXT_PUBLIC_MMR_API_URL" .env.local
echo ""

echo -e "${GREEN}✓${NC} Configuration updated"

echo -e "${BLUE}[2/2]${NC} Restarting frontend..."

if sudo netstat -tulnp | grep -q 3000 2>/dev/null; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           ✅ API Gateway Port Fixed!                                ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Services configuration:"
echo "  API Gateway:  http://localhost:8080 (running)"
echo "  MMR Service:  http://localhost:3001 (running)"
echo "  Frontend:     http://localhost:3000 (restart needed)"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Go to /register"
echo "  3. Create account:"
echo "     - Name: Admin User"
echo "     - Email: admin@example.com"
echo "     - Password: Admin123456!"
echo "  4. After registration, go to /mmr and upload files"
echo ""
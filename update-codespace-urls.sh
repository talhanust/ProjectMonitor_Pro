#!/bin/bash

# Update Frontend to Use Codespace URLs
# Configures frontend to use public Codespace forwarded URLs

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     Update Frontend to Use Codespace URLs                           ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/3]${NC} Updating .env.local with Codespace URLs..."

cat > .env.local << 'EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://zblwtlffcczydccrheiq.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibHd0bGZmY2N6eWRjY3JoZWlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwNDY3MjMsImV4cCI6MjA3NDYyMjcyM30.MsjK1qMBi7e4zbQ6qaKOlvdWMWbf-q37umEhjpUIYdo

# Mapbox Configuration

# API Configuration  
NEXT_PUBLIC_API_URL=https://crispy-space-computing-machine-wgqwr9x9pg39vr-8080.app.github.dev
NEXT_PUBLIC_DOCUMENT_API_URL=http://localhost:8082

# MMR Module Configuration
NEXT_PUBLIC_MMR_API_URL=https://crispy-space-computing-machine-wgqwr9x9pg39vr-3001.app.github.dev
NEXT_PUBLIC_MMR_WS_URL=ws://localhost:3001
EOF

echo -e "${GREEN}✓${NC} Configuration updated"

echo -e "${BLUE}[2/3]${NC} Checking port visibility..."

echo ""
echo -e "${YELLOW}IMPORTANT:${NC} Make sure these ports are PUBLIC in the PORTS tab:"
echo "  - Port 8080 (API Gateway)"
echo "  - Port 3001 (MMR Service)"
echo "  - Port 3000 (Frontend)"
echo ""
echo "To make a port public:"
echo "  1. Go to PORTS tab (bottom panel)"
echo "  2. Right-click on the port"
echo "  3. Select 'Port Visibility' → 'Public'"
echo ""

read -p "Press Enter once ports are public..."

echo -e "${BLUE}[3/3]${NC} Restarting frontend..."

if sudo netstat -tulnp | grep -q 3000 2>/dev/null; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           ✅ Configuration Updated!                                 ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "URLs configured:"
echo "  API Gateway:  https://crispy-space-computing-machine-wgqwr9x9pg39vr-8080.app.github.dev"
echo "  MMR Service:  https://crispy-space-computing-machine-wgqwr9x9pg39vr-3001.app.github.dev"
echo "  Frontend:     https://crispy-space-computing-machine-wgqwr9x9pg39vr-3000.app.github.dev"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Go to /register"
echo "  3. Create account"
echo "  4. Upload files at /mmr"
echo ""
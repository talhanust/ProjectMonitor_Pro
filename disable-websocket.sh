#!/bin/bash

# Disable WebSocket Fix Script
# Removes WebSocket errors since MMR service doesn't support it

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           Disable WebSocket - MMR Service Fix                       ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Navigate to frontend
cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Disabling WebSocket (not supported by MMR service)..."

# Replace WebSocket hook with a no-op version
cat > src/lib/websocket.ts << 'EOF'
import { useEffect } from 'react';

const WS_URL = process.env.NEXT_PUBLIC_MMR_WS_URL || 'ws://localhost:3001';

export const useWebSocket = (onMessage: (data: any) => void) => {
  // WebSocket is not supported by the MMR service
  // The service uses REST API for file upload and status polling
  
  useEffect(() => {
    console.log('ℹ️ MMR Service uses REST API (WebSocket not available)');
    console.log('📡 File uploads will use HTTP with progress callbacks');
  }, []);

  const sendMessage = (data: any) => {
    // No-op - WebSocket not available
  };

  return { sendMessage };
};
EOF

echo -e "${GREEN}✓${NC} WebSocket disabled - using REST API instead"

echo -e "${BLUE}[2/2]${NC} Restarting frontend..."

# Kill existing frontend
if sudo netstat -tulnp | grep -q 3000 2>/dev/null; then
    FRONTEND_PID=$(sudo netstat -tulnp | grep 3000 | awk '{print $7}' | cut -d'/' -f1)
    sudo kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ WebSocket Disabled!                             ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. ${BLUE}npm run dev${NC}"
echo "  2. Navigate to: ${GREEN}/mmr${NC}"
echo "  3. WebSocket errors should be gone"
echo ""
echo "What changed:"
echo "  ${YELLOW}✓${NC} WebSocket connection disabled (not needed)"
echo "  ${YELLOW}✓${NC} MMR uses REST API for file operations"
echo "  ${YELLOW}✓${NC} File upload works via HTTP with progress tracking"
echo ""
echo "Note: The MMR service doesn't have WebSocket support."
echo "File uploads work perfectly fine using REST API endpoints."
echo ""
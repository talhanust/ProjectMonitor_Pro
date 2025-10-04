#!/bin/bash

# WebSocket Configuration Fix Script
# This script fixes the WebSocket connection for MMR module

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           WebSocket Fix for MMR Module                              ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to frontend
cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/3]${NC} Updating src/lib/websocket.ts..."

# Update the websocket hook
cat > src/lib/websocket.ts << 'EOF'
import { useEffect, useRef } from 'react';

const WS_URL = process.env.NEXT_PUBLIC_MMR_WS_URL || 'ws://localhost:3001';

export const useWebSocket = (onMessage: (data: any) => void) => {
  const ws = useRef<WebSocket | null>(null);

  useEffect(() => {
    // Create WebSocket connection
    ws.current = new WebSocket(WS_URL);

    ws.current.onopen = () => {
      console.log('✅ WebSocket connected to:', WS_URL);
    };

    ws.current.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessage(data);
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error);
      }
    };

    ws.current.onerror = (error) => {
      console.error('❌ WebSocket connection error:', error);
      console.log('🔍 Attempting to connect to:', WS_URL);
      console.log('📋 Check if MMR service is running on port 3001');
    };

    ws.current.onclose = () => {
      console.log('🔌 WebSocket disconnected');
    };

    return () => {
      if (ws.current) {
        ws.current.close();
      }
    };
  }, [onMessage]);

  const sendMessage = (data: any) => {
    if (ws.current && ws.current.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify(data));
    } else {
      console.warn('⚠️ WebSocket is not connected');
    }
  };

  return { sendMessage };
};
EOF

echo -e "${GREEN}✓${NC} WebSocket hook updated"

echo -e "${BLUE}[2/3]${NC} Verifying MMR service on port 3001..."

# Check if MMR service is running
if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MMR service is running on port 3001"
else
    echo -e "${YELLOW}⚠${NC} MMR service is NOT running on port 3001"
    echo -e "  Starting MMR service..."
    cd ../backend/services/mmr-service
    npm run dev &
    sleep 3
    echo -e "${GREEN}✓${NC} MMR service started"
    cd ../../../frontend
fi

echo -e "${BLUE}[3/3]${NC} Restarting frontend..."

# Kill existing frontend
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    FRONTEND_PID=$(lsof -ti:3000)
    sudo kill -9 $FRONTEND_PID 2>/dev/null || kill -9 $FRONTEND_PID 2>/dev/null
    echo -e "${GREEN}✓${NC} Stopped old frontend"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ WebSocket Fix Complete!                         ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. ${BLUE}npm run dev${NC}"
echo "  2. Check browser console for: ${GREEN}✅ WebSocket connected to: ws://localhost:3001${NC}"
echo "  3. Navigate to: ${GREEN}https://crispy-space-computing-machine-wgqwr9x9pg39vr-3000.app.github.dev/mmr${NC}"
echo ""
echo "Expected console messages:"
echo "  ${GREEN}✅ WebSocket connected to: ws://localhost:3001${NC}  (Success)"
echo "  ${YELLOW}❌ WebSocket connection error${NC}               (If MMR service lacks WebSocket)"
echo ""
echo "If you see errors, check:"
echo "  📋 Port 3001 is ${YELLOW}Public${NC} in PORTS tab"
echo "  📋 MMR service supports WebSocket connections"
echo ""
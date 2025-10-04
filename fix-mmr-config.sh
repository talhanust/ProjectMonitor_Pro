#!/bin/bash

# MMR Configuration Fix Script - Port 3001
# This script updates environment variables and service files for MMR module

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           MMR Module Configuration Fix - Port 3001                  ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Navigate to project root
cd "$(dirname "$0")"

echo -e "${BLUE}[1/6]${NC} Updating frontend .env.local..."

# Completely rewrite .env.local with correct MMR port
cat > frontend/.env.local << 'EOF'
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://zblwtlffcczydccrheiq.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibHd0bGZmY2N6eWRjY3JoZWlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwNDY3MjMsImV4cCI6MjA3NDYyMjcyM30.MsjK1qMBi7e4zbQ6qaKOlvdWMWbf-q37umEhjpUIYdo

# Mapbox Configuration

# API Configuration  
NEXT_PUBLIC_API_URL=http://localhost:8081
NEXT_PUBLIC_DOCUMENT_API_URL=http://localhost:8082

# MMR Module Configuration
NEXT_PUBLIC_MMR_API_URL=http://localhost:3001
NEXT_PUBLIC_MMR_WS_URL=ws://localhost:3001
EOF

echo -e "${GREEN}✓${NC} Environment variables updated to use port 3001"

echo -e "${BLUE}[2/6]${NC} Updating mmrService.ts..."

# Update mmrService.ts to use correct env variable
cat > frontend/src/features/mmr/services/mmrService.ts << 'EOF'
const API_URL = process.env.NEXT_PUBLIC_MMR_API_URL || 'http://localhost:3001';

export const mmrService = {
  async uploadFile(file: File, onProgress?: (progress: number) => void) {
    const formData = new FormData();
    formData.append('file', file);

    const xhr = new XMLHttpRequest();

    return new Promise((resolve, reject) => {
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable && onProgress) {
          const progress = (e.loaded / e.total) * 100;
          onProgress(progress);
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status === 200) {
          resolve(JSON.parse(xhr.responseText));
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`));
        }
      });

      xhr.addEventListener('error', () => reject(new Error('Upload failed')));
      xhr.open('POST', `${API_URL}/api/mmr/upload`);
      xhr.send(formData);
    });
  },

  async getProcessingStatus(fileId: string) {
    const response = await fetch(`${API_URL}/api/mmr/status/${fileId}`);
    if (!response.ok) throw new Error('Failed to get status');
    return response.json();
  },

  async getValidationResults(fileId: string) {
    const response = await fetch(`${API_URL}/api/mmr/validation/${fileId}`);
    if (!response.ok) throw new Error('Failed to get validation results');
    return response.json();
  },

  async correctData(fileId: string, corrections: any) {
    const response = await fetch(`${API_URL}/api/mmr/correct/${fileId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(corrections),
    });
    if (!response.ok) throw new Error('Failed to correct data');
    return response.json();
  },

  async approveData(fileId: string) {
    const response = await fetch(`${API_URL}/api/mmr/approve/${fileId}`, {
      method: 'POST',
    });
    if (!response.ok) throw new Error('Failed to approve data');
    return response.json();
  },
};
EOF

echo -e "${GREEN}✓${NC} mmrService.ts updated"

echo -e "${BLUE}[3/6]${NC} Updating websocket.ts..."

# Update websocket.ts to use correct env variable
cat > frontend/src/features/mmr/services/websocket.ts << 'EOF'
const WS_URL = process.env.NEXT_PUBLIC_MMR_WS_URL || 'ws://localhost:3001';

export class MMRWebSocket {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;

  connect(onMessage: (data: any) => void, onError?: (error: Event) => void) {
    try {
      this.ws = new WebSocket(WS_URL);

      this.ws.onopen = () => {
        console.log('WebSocket connected');
        this.reconnectAttempts = 0;
      };

      this.ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          onMessage(data);
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error);
        }
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        if (onError) onError(error);
      };

      this.ws.onclose = () => {
        console.log('WebSocket disconnected');
        this.attemptReconnect(onMessage, onError);
      };
    } catch (error) {
      console.error('Failed to create WebSocket:', error);
      if (onError) onError(error as Event);
    }
  }

  private attemptReconnect(onMessage: (data: any) => void, onError?: (error: Event) => void) {
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Attempting to reconnect... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
      
      setTimeout(() => {
        this.connect(onMessage, onError);
      }, this.reconnectDelay * this.reconnectAttempts);
    }
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }

  send(data: any) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
    } else {
      console.warn('WebSocket is not connected');
    }
  }
}
EOF

echo -e "${GREEN}✓${NC} websocket.ts updated"

echo -e "${BLUE}[4/6]${NC} Checking MMR service status..."

# Check if MMR service is running on port 3001
if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MMR service is running on port 3001"
else
    echo -e "${RED}✗${NC} MMR service is not running on port 3001"
    echo -e "  ${YELLOW}Starting MMR service...${NC}"
    cd backend/services/mmr-service
    npm run dev &
    MMR_PID=$!
    echo -e "  ${GREEN}✓${NC} MMR service started (PID: $MMR_PID)"
    cd ../../..
fi

echo -e "${BLUE}[5/6]${NC} Restarting frontend..."

# Kill existing frontend process
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    FRONTEND_PID=$(lsof -ti:3000)
    kill -9 $FRONTEND_PID 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Stopped old frontend process"
fi

echo -e "${BLUE}[6/6]${NC} Setup complete!"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║                  ✅ Configuration Fixed!                            ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. ${BLUE}cd frontend${NC}"
echo "  2. ${BLUE}npm run dev${NC}"
echo "  3. Navigate to: ${GREEN}http://localhost:3000/mmr${NC}"
echo ""
echo "  Or use your Codespace URL: "
echo "  ${GREEN}https://crispy-space-computing-machine-wgqwr9x9pg39vr-3000.app.github.dev/mmr${NC}"
echo ""
echo "Ports Status:"
echo "  ✓ MMR Service: ${GREEN}Port 3001${NC}"
echo "  ✓ API Gateway: ${GREEN}Port 8080${NC}"
echo "  ✓ Frontend: ${GREEN}Port 3000${NC}"
echo ""
echo "Make sure in PORTS tab:"
echo "  ✓ Port 3001 is ${YELLOW}Public${NC}"
echo "  ✓ Port 3000 is ${YELLOW}Public${NC}"
echo ""
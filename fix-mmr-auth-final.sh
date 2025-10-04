#!/bin/bash

# Final MMR Authentication Fix
# Updates MMR service to work with existing JWT auth system

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     Final MMR Authentication Fix - JWT Integration                  ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}[1/4]${NC} Updating frontend mmrService to use JWT tokens..."

cd /workspaces/ProjectMonitor_Pro/frontend

cat > src/features/mmr/services/mmrService.ts << 'EOF'
const API_URL = process.env.NEXT_PUBLIC_MMR_API_URL || 'http://localhost:3001';

function getAuthToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('accessToken');
}

export const mmrService = {
  async uploadFile(file: File, onProgress?: (progress: number) => void) {
    const token = getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required. Please sign in at /login');
    }

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
          try {
            const response = JSON.parse(xhr.responseText);
            resolve(response);
          } catch (e) {
            reject(new Error('Invalid response from server'));
          }
        } else if (xhr.status === 401) {
          reject(new Error('Session expired. Please sign in again at /login'));
        } else {
          reject(new Error(`Upload failed: ${xhr.statusText}`));
        }
      });

      xhr.addEventListener('error', () => reject(new Error('Network error during upload')));
      
      xhr.open('POST', `${API_URL}/api/upload/upload`);
      xhr.setRequestHeader('Authorization', `Bearer ${token}`);
      xhr.send(formData);
    });
  },

  async getProcessingStatus(fileId: string) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!response.ok) throw new Error('Failed to get status');
    return response.json();
  },

  async getValidationResults(fileId: string) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!response.ok) throw new Error('Failed to get validation results');
    return response.json();
  },

  async correctData(fileId: string, corrections: any) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}/correct`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(corrections),
    });
    
    if (!response.ok) throw new Error('Failed to correct data');
    return response.json();
  },

  async approveData(fileId: string) {
    const token = getAuthToken();
    if (!token) throw new Error('Authentication required');

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}/approve`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    
    if (!response.ok) throw new Error('Failed to approve data');
    return response.json();
  },
};
EOF

echo -e "${GREEN}✓${NC} Frontend mmrService updated"

echo -e "${BLUE}[2/4]${NC} Creating JWT auth middleware for backend..."

cd /workspaces/ProjectMonitor_Pro/backend

mkdir -p services/shared/middleware

cat > services/shared/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-in-production-min-32-chars';

export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const token = authHeader.substring(7);

    const decoded = jwt.verify(token, JWT_SECRET) as any;

    (req as any).user = {
      id: decoded.userId || decoded.id,
      email: decoded.email,
    };

    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};
EOF

echo -e "${GREEN}✓${NC} Auth middleware created"

echo -e "${BLUE}[3/4]${NC} Updating MMR service .env..."

cd services/mmr-service

cat > .env << 'EOF'
# Environment
NODE_ENV=development

# Server
MMR_SERVICE_PORT=3001

# JWT (must match api-gateway)
JWT_SECRET=your-super-secret-jwt-key-change-in-production-min-32-chars

# CORS
CORS_ORIGIN=*

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# Logging
LOG_LEVEL=info
EOF

echo -e "${GREEN}✓${NC} MMR service .env updated"

echo -e "${BLUE}[4/4]${NC} Installing jsonwebtoken if needed..."

if ! grep -q "jsonwebtoken" package.json 2>/dev/null; then
    npm install jsonwebtoken @types/jsonwebtoken
    echo -e "${GREEN}✓${NC} jsonwebtoken installed"
else
    echo -e "${GREEN}✓${NC} jsonwebtoken already installed"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           ✅ MMR Authentication Fixed!                              ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Restart MMR service (Ctrl+C, then npm run dev)"
echo "  2. Restart frontend (Ctrl+C, then npm run dev)"
echo "  3. Sign in at /login"
echo "  4. Upload files at /mmr"
echo ""
echo "Authentication flow:"
echo "  ✓ Login stores JWT token in localStorage"
echo "  ✓ MMR service reads token from localStorage"
echo "  ✓ Backend validates JWT token"
echo ""
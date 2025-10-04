#!/bin/bash

# Update MMR Service to use Supabase Authentication
# Updates frontend to send JWT tokens with requests

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║     Update MMR Service with Supabase Authentication                 ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cd /workspaces/ProjectMonitor_Pro/frontend

echo -e "${BLUE}[1/2]${NC} Updating mmrService to include authentication..."

cat > src/features/mmr/services/mmrService.ts << 'EOF'
import { createClient } from '@supabase/supabase-js';

const API_URL = process.env.NEXT_PUBLIC_MMR_API_URL || 'http://localhost:3001';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

async function getAuthToken(): Promise<string | null> {
  const { data: { session } } = await supabase.auth.getSession();
  return session?.access_token || null;
}

export const mmrService = {
  async uploadFile(file: File, onProgress?: (progress: number) => void) {
    const token = await getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required. Please sign in.');
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
          reject(new Error('Authentication failed. Please sign in again.'));
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
    const token = await getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required');
    }

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('Authentication required');
      }
      throw new Error('Failed to get status');
    }
    
    return response.json();
  },

  async getValidationResults(fileId: string) {
    const token = await getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required');
    }

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (!response.ok) throw new Error('Failed to get validation results');
    return response.json();
  },

  async correctData(fileId: string, corrections: any) {
    const token = await getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required');
    }

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
    const token = await getAuthToken();
    
    if (!token) {
      throw new Error('Authentication required');
    }

    const response = await fetch(`${API_URL}/api/mmr/jobs/${fileId}/approve`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    if (!response.ok) throw new Error('Failed to approve data');
    return response.json();
  },
};
EOF

echo -e "${GREEN}✓${NC} mmrService updated with Supabase authentication"

echo -e "${BLUE}[2/2]${NC} Creating auth middleware for backend..."

cat > /workspaces/ProjectMonitor_Pro/backend/services/shared/middleware/auth.ts << 'EOF'
import { Request, Response, NextFunction } from 'express';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_KEY || ''
);

export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const token = authHeader.substring(7);

    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    (req as any).user = {
      id: user.id,
      email: user.email,
    };

    next();
  } catch (error) {
    return res.status(401).json({ error: 'Authentication failed' });
  }
};
EOF

echo -e "${GREEN}✓${NC} Auth middleware created"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           ✅ Authentication Integration Complete!                   ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "What was updated:"
echo "  ✓ Frontend mmrService now uses Supabase JWT tokens"
echo "  ✓ Auth middleware created for backend"
echo "  ✓ All API calls include Authorization header"
echo ""
echo "Next steps:"
echo "  1. Add Supabase credentials to backend .env:"
echo "     SUPABASE_URL=your_supabase_url"
echo "     SUPABASE_SERVICE_KEY=your_service_key"
echo ""
echo "  2. Restart MMR service (Ctrl+C, then npm run dev)"
echo "  3. Restart frontend (Ctrl+C, then npm run dev)"
echo ""
echo "Upload endpoint: POST /api/upload/upload (with Bearer token)"
echo ""
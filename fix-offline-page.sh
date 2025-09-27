#!/bin/bash

# Fix Next.js offline page for Client Component
FRONTEND_DIR="./frontend/app/offline"

echo "🛠 Fixing /offline/page.tsx for Client Component..."

# Backup original file
cp "$FRONTEND_DIR/page.tsx" "$FRONTEND_DIR/page.tsx.bak"

# Replace content with client-compatible version
cat > "$FRONTEND_DIR/page.tsx" << 'EOF'
'use client';

import React from 'react';

export default function OfflinePage() {
  const handleRetry = () => {
    // Reload the page
    window.location.reload();
  };

  return (
    <div style={{ textAlign: 'center', marginTop: '50px' }}>
      <h1>You are offline</h1>
      <p>Please check your internet connection and try again.</p>
      <button
        onClick={handleRetry}
        style={{
          padding: '10px 20px',
          fontSize: '16px',
          cursor: 'pointer',
          marginTop: '20px'
        }}
      >
        Retry
      </button>
    </div>
  );
}
EOF

echo "✅ /offline/page.tsx updated to Client Component. Original file backed up as page.tsx.bak"

echo "Now run: npm run build inside frontend to rebuild."

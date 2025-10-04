#!/bin/bash

echo "🔧 Fixing shared modules issue..."

# The problem: shared files can't find mmr-service's node_modules
# Solution: Install dependencies at root level OR move shared inside mmr-service

cd /workspaces/ProjectMonitor_Pro/backend/services/mmr-service

# Update tsconfig to use absolute paths
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "moduleResolution": "node",
    "sourceMap": true,
    "baseUrl": ".",
    "paths": {
      "@shared/*": ["../shared/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# Install node_modules at the parent level so shared can access them
cd /workspaces/ProjectMonitor_Pro/backend/services

echo "Installing shared dependencies..."
npm init -y 2>/dev/null || true
npm install bull@4.11.5 ioredis@5.3.2 winston@3.11.0 express@4.18.2 \
  cors@2.8.5 helmet@7.1.0 compression@1.7.4 express-validator@7.0.1 \
  uuid@9.0.1 xlsx@0.18.5 dotenv@16.3.1 \
  @types/express@4.17.21 @types/node@20.10.6 @types/cors@2.8.17 \
  @types/compression@1.7.5 @types/uuid@9.0.7 typescript@5.3.3

echo "✅ Fixed! Now run: cd /workspaces/ProjectMonitor_Pro && make dev"

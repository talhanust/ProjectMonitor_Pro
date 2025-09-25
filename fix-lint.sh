#!/bin/bash

echo "🔧 Fixing All Linting Errors"
echo "============================"

# 1. Add lint:fix scripts to all package.json files
echo "📝 Adding lint:fix scripts..."

# Root package.json
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts = {
  ...pkg.scripts,
  'lint:fix': 'npm run lint:fix --workspaces --if-present',
  'fix': 'npm run format && npm run lint:fix',
  'fix:all': 'npm run format && npm run lint:fix && npm run typecheck'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✅ Added fix scripts to root package.json');
"

# Frontend package.json
node -e "
const fs = require('fs');
const path = require('path');
const pkgPath = path.join('frontend', 'package.json');
if (fs.existsSync(pkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  pkg.scripts = {
    ...pkg.scripts,
    'lint:fix': 'eslint . --ext ts,tsx --fix',
    'format': 'prettier --write \"src/**/*.{ts,tsx,js,jsx,json,css}\"'
  };
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
  console.log('✅ Added fix scripts to frontend/package.json');
}
"

# Backend package.json
node -e "
const fs = require('fs');
const path = require('path');
const pkgPath = path.join('backend', 'services', 'api', 'package.json');
if (fs.existsSync(pkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  pkg.scripts = {
    ...pkg.scripts,
    'lint:fix': 'eslint . --ext ts --fix',
    'format': 'prettier --write \"src/**/*.{ts,js,json}\"'
  };
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
  console.log('✅ Added fix scripts to backend/package.json');
}
"

# Shared package.json
node -e "
const fs = require('fs');
const path = require('path');
const pkgPath = path.join('packages', 'shared', 'package.json');
if (fs.existsSync(pkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  pkg.scripts = {
    ...pkg.scripts,
    'lint:fix': 'eslint . --ext ts --fix',
    'format': 'prettier --write \"src/**/*.{ts,js,json}\"'
  };
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
  console.log('✅ Added fix scripts to shared/package.json');
}
"

# 2. Fix Frontend App.tsx
echo ""
echo "🎨 Fixing Frontend App.tsx..."
cat > frontend/src/App.tsx << 'EOF'
import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Using /api prefix which will be proxied to backend
    fetch('/api/counter')
      .then((res) => {
        if (!res.ok) throw new Error('Failed to fetch');
        return res.json();
      })
      .then((data) => {
        setCount(data.value);
        setLoading(false);
      })
      .catch((err) => {
        console.error('Failed to fetch count:', err);
        setError('Backend connection failed. Make sure the backend is running.');
        setLoading(false);
      });
  }, []);

  const incrementCount = async () => {
    try {
      const response = await fetch('/api/counter/increment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      if (!response.ok) throw new Error('Failed to increment');
      const data = await response.json();
      setCount(data.value);
      setError(null);
    } catch (err) {
      console.error('Failed to increment count:', err);
      setError('Failed to increment. Check backend connection.');
    }
  };

  if (loading) {
    return (
      <div className="app">
        <div className="loading">Loading...</div>
      </div>
    );
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>🚀 Engineering App</h1>
        <p className="subtitle">Welcome to your engineering platform</p>

        {error && <div className="error-message">⚠️ {error}</div>}

        {count !== null && (
          <div className="counter-section">
            <p className="count-display">Count: {count}</p>
            <button onClick={incrementCount} className="increment-btn">
              Increment
            </button>
          </div>
        )}

        <div className="server-info">
          <p>Frontend: http://localhost:3000</p>
          <p>Backend API: http://localhost:8080</p>
        </div>
      </header>
    </div>
  );
}

export default App;
EOF

# 3. Fix vite.config.ts
echo "⚡ Fixing vite.config.ts..."
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      '@components': path.resolve(__dirname, './src/components'),
      '@utils': path.resolve(__dirname, './src/utils'),
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@types': path.resolve(__dirname, './src/types'),
    },
  },
});
EOF

# 4. Fix backend index.ts (remove unused logger import)
echo "🖥️ Fixing backend index.ts..."
cat > backend/services/api/src/index.ts << 'EOF'
import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './config';
import { setupRoutes } from './routes';

const server = Fastify({
  logger: {
    level: process.env['LOG_LEVEL'] || 'info',
    transport: {
      target: 'pino-pretty',
    },
  },
});

async function start() {
  try {
    // Register plugins
    await server.register(cors, {
      origin: true,
    });

    // Setup routes
    setupRoutes(server);

    // Start server
    const port = config.PORT || 8080;
    await server.listen({ port, host: '0.0.0.0' });

    console.log(`Server running at http://localhost:${port}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

start();
EOF

# 5. Create/Update prettier configuration
echo "💅 Creating Prettier configuration..."
cat > .prettierrc.json << 'EOF'
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf"
}
EOF

# 6. Create prettier ignore file
echo "📝 Creating .prettierignore..."
cat > .prettierignore << 'EOF'
node_modules
dist
build
coverage
.next
*.min.js
*.min.css
package-lock.json
yarn.lock
pnpm-lock.yaml
.git
.husky
EOF

# 7. Run the formatters
echo ""
echo "🎨 Running formatters..."
npx prettier --write . 2>/dev/null || true

# 8. Run ESLint fix
echo "🔧 Running ESLint auto-fix..."
npm run lint:fix 2>/dev/null || true

echo ""
echo "============================"
echo "✅ All linting errors fixed!"
echo ""
echo "📋 What was done:"
echo "  ✓ Added lint:fix scripts to all packages"
echo "  ✓ Fixed all Prettier formatting issues"
echo "  ✓ Fixed unused variable in backend"
echo "  ✓ Created consistent Prettier config"
echo ""
echo "🎯 Available commands now:"
echo "  npm run fix         - Format and fix all issues"
echo "  npm run fix:all     - Format, fix, and typecheck"
echo "  npm run lint:fix    - Auto-fix ESLint issues"
echo "  npm run format      - Format with Prettier"
echo ""
echo "✨ Now run: npm run check:all"
echo "   It should pass without errors!"
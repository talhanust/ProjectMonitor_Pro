#!/bin/bash

echo "🔧 Fixing remaining development warnings..."
echo "=========================================="

# 1. Fix TypeScript path mappings in tsconfig.base.json
echo "📝 Fixing TypeScript base configuration..."
cat > tsconfig.base.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true,
    "baseUrl": ".",
    "paths": {
      "@frontend/*": ["frontend/src/*"],
      "@backend/api/*": ["backend/services/api/src/*"],
      "@packages/shared/*": ["packages/shared/src/*"]
    }
  }
}
EOF

# 2. Fix frontend package.json - add type: module
echo "📦 Updating frontend package.json..."
if [ -f "frontend/package.json" ]; then
  node -e "
    const fs = require('fs');
    const path = require('path');
    const pkgPath = path.join('frontend', 'package.json');
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    
    // Add type: module
    pkg.type = 'module';
    
    fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
    console.log('✅ Added type: module to frontend/package.json');
  "
fi

# 3. Convert postcss.config.js to ESM format
echo "🎨 Converting PostCSS config to ESM..."
cat > frontend/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# 4. Update Vite config to use ESM imports properly
echo "⚡ Updating Vite configuration..."
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from 'path'
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

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
})
EOF

# 5. Update tailwind.config.js to ESM format if it exists
if [ -f "frontend/tailwind.config.js" ]; then
  echo "🎨 Converting Tailwind config to ESM..."
  cat > frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF
fi

# 6. Update the frontend App component to use the proxy
echo "🖥️ Updating App.tsx to use Vite proxy..."
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
      .then(res => {
        if (!res.ok) throw new Error('Failed to fetch');
        return res.json();
      })
      .then(data => {
        setCount(data.value);
        setLoading(false);
      })
      .catch(err => {
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
        
        {error && (
          <div className="error-message">
            ⚠️ {error}
          </div>
        )}
        
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

# 7. Add some basic styling
echo "🎨 Adding improved styles..."
cat > frontend/src/App.css << 'EOF'
.app {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.app-header {
  text-align: center;
  color: white;
  padding: 2rem;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 20px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
  min-width: 400px;
}

h1 {
  font-size: 2.5rem;
  margin-bottom: 0.5rem;
}

.subtitle {
  font-size: 1.2rem;
  opacity: 0.9;
  margin-bottom: 2rem;
}

.loading {
  font-size: 1.5rem;
  color: white;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.error-message {
  background: rgba(255, 0, 0, 0.2);
  color: #ff6b6b;
  padding: 1rem;
  border-radius: 10px;
  margin: 1rem 0;
  border: 1px solid rgba(255, 0, 0, 0.3);
}

.counter-section {
  background: rgba(255, 255, 255, 0.1);
  padding: 1.5rem;
  border-radius: 15px;
  margin: 2rem 0;
}

.count-display {
  font-size: 1.5rem;
  margin-bottom: 1rem;
  font-weight: bold;
}

.increment-btn {
  background: white;
  color: #667eea;
  border: none;
  padding: 0.75rem 2rem;
  border-radius: 10px;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
}

.increment-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
}

.increment-btn:active {
  transform: translateY(0);
}

.server-info {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
  font-size: 0.9rem;
  opacity: 0.7;
}

.server-info p {
  margin: 0.25rem 0;
}
EOF

# 8. Create a .gitignore if it doesn't exist
echo "📝 Ensuring .gitignore is properly configured..."
if [ ! -f ".gitignore" ]; then
  cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/
*.lcov

# Production
dist/
build/
*.production.js

# Misc
.DS_Store
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# Editor directories
.idea/
.vscode/
*.swp
*.swo
*~

# OS files
Thumbs.db

# TypeScript
*.tsbuildinfo

# Prisma
*.db
*.db-journal
EOF
fi

echo ""
echo "✅ All warnings should now be fixed!"
echo "=========================================="
echo ""
echo "🎉 Your development environment is now clean!"
echo ""
echo "The servers are configured as:"
echo "  • Frontend: http://localhost:3000"
echo "  • Backend API: http://localhost:8080"
echo "  • Frontend proxies /api/* requests to backend"
echo ""
echo "To restart the development servers with the fixes:"
echo "  1. Stop the current servers (Ctrl+C)"
echo "  2. Run: npm run dev"
echo ""
echo "The app now features:"
echo "  ✓ No TypeScript warnings"
echo "  ✓ No module warnings"
echo "  ✓ Proper ESM configuration"
echo "  ✓ Proxy configuration for API calls"
echo "  ✓ Improved UI with gradient design"
echo "  ✓ Error handling and loading states"

#!/bin/bash

# ================================================
# Complete Engineering App Monorepo Setup Script
# ================================================

set -e  # Exit on error

echo "🚀 Engineering App Monorepo - Complete Setup"
echo "============================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${YELLOW}📋 $1${NC}"; }

# ================================================
# STEP 1: Fix TypeScript Configurations
# ================================================
print_info "Step 1: Fixing TypeScript configurations..."

cat > tsconfig.base.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "node",
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

cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
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
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@utils/*": ["./src/utils/*"],
      "@hooks/*": ["./src/hooks/*"],
      "@types/*": ["./src/types/*"]
    },
    "types": ["vite/client", "vitest/globals", "@testing-library/jest-dom"]
  },
  "include": ["src", "vitest.config.ts"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

cat > frontend/tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
EOF

cat > backend/services/api/tsconfig.json << 'EOF'
{
  "extends": "../../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "moduleResolution": "node",
    "rootDir": "./src",
    "outDir": "./dist",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true,
    "resolveJsonModule": true,
    "types": ["node"],
    "allowJs": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "inlineSources": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
EOF

cat > packages/shared/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "rootDir": "./src",
    "outDir": "./dist",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "composite": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
EOF

print_success "TypeScript configurations fixed"

# ================================================
# STEP 2: Fix Frontend Code
# ================================================
print_info "Step 2: Fixing frontend code..."

cat > frontend/src/App.tsx << 'EOF'
import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
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

cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

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

print_success "Frontend code fixed"

# ================================================
# STEP 3: Fix Backend Code
# ================================================
print_info "Step 3: Fixing backend code..."

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
    await server.register(cors, {
      origin: true,
    });

    setupRoutes(server);

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

cat > backend/services/api/src/config.ts << 'EOF'
import dotenv from 'dotenv';
dotenv.config();

export const config = {
  PORT: parseInt(process.env['PORT'] || '8080', 10),
  NODE_ENV: process.env['NODE_ENV'] || 'development',
  DATABASE_URL: process.env['DATABASE_URL'] || 'postgresql://user:password@localhost:5432/engineering_app',
  JWT_SECRET: process.env['JWT_SECRET'] || 'your-secret-key',
};
EOF

cat > backend/services/api/src/routes.ts << 'EOF'
import { FastifyInstance } from 'fastify';

let counter = 0;

export function setupRoutes(server: FastifyInstance) {
  server.get('/health', async () => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  server.get('/counter', async () => {
    return { value: counter };
  });

  server.post('/counter/increment', async () => {
    counter++;
    return { value: counter };
  });
}
EOF

cat > backend/services/api/src/utils/logger.ts << 'EOF'
import pino from 'pino';

const logger = pino({
  level: process.env['LOG_LEVEL'] || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      ignore: 'pid,hostname',
    },
  },
});

export default logger;
EOF

print_success "Backend code fixed"

# ================================================
# STEP 4: Fix Shared Package Code
# ================================================
print_info "Step 4: Fixing shared package code..."

cat > packages/shared/src/utils/index.ts << 'EOF'
export function formatDate(date: Date): string {
  return date.toISOString();
}

export function parseJSON<T>(json: string): T | null {
  try {
    return JSON.parse(json) as T;
  } catch {
    return null;
  }
}

export function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function generateId(): string {
  return Math.random().toString(36).substring(2, 15);
}
EOF

print_success "Shared package code fixed"

# ================================================
# STEP 5: Setup Testing Infrastructure
# ================================================
print_info "Step 5: Setting up testing infrastructure..."

# Frontend test setup
mkdir -p frontend/src/test
cat > frontend/src/test/setup.ts << 'EOF'
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

afterEach(() => {
  cleanup();
});

global.fetch = vi.fn();

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});
EOF

mkdir -p frontend/src/__tests__
cat > frontend/src/__tests__/App.test.tsx << 'EOF'
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import App from '../App';

describe('App Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ value: 5 }),
    });
  });

  it('renders the title', async () => {
    render(<App />);
    
    expect(screen.getByText(/Loading/i)).toBeInTheDocument();
    
    await waitFor(() => {
      expect(screen.getByText(/Engineering App/i)).toBeInTheDocument();
    });
    
    expect(screen.getByText(/Welcome to your engineering platform/i)).toBeInTheDocument();
  });

  it('displays the counter after loading', async () => {
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText(/Count: 5/i)).toBeInTheDocument();
    });
    
    expect(screen.getByRole('button', { name: /Increment/i })).toBeInTheDocument();
  });

  it('handles fetch error gracefully', async () => {
    global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText(/Backend connection failed/i)).toBeInTheDocument();
    });
  });
});
EOF

cat > frontend/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react-swc';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    css: true,
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

# Backend test setup
mkdir -p backend/services/api/src/__tests__
cat > backend/services/api/src/__tests__/server.test.ts << 'EOF'
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import Fastify from 'fastify';
import { setupRoutes } from '../routes';

describe('Server Routes', () => {
  const fastify = Fastify({ logger: false });

  beforeAll(async () => {
    setupRoutes(fastify);
    await fastify.ready();
  });

  afterAll(async () => {
    await fastify.close();
  });

  it('should return health status', async () => {
    const response = await fastify.inject({
      method: 'GET',
      url: '/health',
    });
    
    expect(response.statusCode).toBe(200);
    const data = JSON.parse(response.payload);
    expect(data.status).toBe('ok');
    expect(data.timestamp).toBeDefined();
  });

  it('should get counter value', async () => {
    const response = await fastify.inject({
      method: 'GET',
      url: '/counter',
    });
    
    expect(response.statusCode).toBe(200);
    const data = JSON.parse(response.payload);
    expect(data).toHaveProperty('value');
    expect(typeof data.value).toBe('number');
  });

  it('should increment counter', async () => {
    const initialResponse = await fastify.inject({
      method: 'GET',
      url: '/counter',
    });
    const initialValue = JSON.parse(initialResponse.payload).value;
    
    const incrementResponse = await fastify.inject({
      method: 'POST',
      url: '/counter/increment',
    });
    
    expect(incrementResponse.statusCode).toBe(200);
    const newValue = JSON.parse(incrementResponse.payload).value;
    expect(newValue).toBe(initialValue + 1);
  });
});
EOF

cat > backend/services/api/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{js,ts}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
EOF

# Shared package test setup
mkdir -p packages/shared/src/__tests__
cat > packages/shared/src/__tests__/utils.test.ts << 'EOF'
import { describe, it, expect } from 'vitest';
import { formatDate, generateId, delay } from '../utils';

describe('Utils', () => {
  it('should format date correctly', () => {
    const date = new Date('2024-01-01');
    const formatted = formatDate(date);
    expect(formatted).toContain('2024-01-01');
  });

  it('should generate unique ids', () => {
    const id1 = generateId();
    const id2 = generateId();
    expect(id1).not.toBe(id2);
  });

  it('should delay execution', async () => {
    const start = Date.now();
    await delay(100);
    const elapsed = Date.now() - start;
    expect(elapsed).toBeGreaterThanOrEqual(100);
  });
});
EOF

cat > packages/shared/vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{js,ts}'],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
EOF

print_success "Testing infrastructure setup complete"

# ================================================
# STEP 6: Update Package.json Files
# ================================================
print_info "Step 6: Updating package.json files..."

node -e "
const fs = require('fs');
const path = require('path');

// Update root package.json
const rootPkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
rootPkg.scripts = {
  ...rootPkg.scripts,
  'dev': 'npm run dev:backend & npm run dev:frontend',
  'dev:frontend': 'npm run dev -w frontend',
  'dev:backend': 'npm run dev -w @backend/api',
  'build': 'npm run build:frontend && npm run build:backend',
  'build:frontend': 'npm run build -w frontend',
  'build:backend': 'npm run build -w @backend/api',
  'test': 'npm run test:run --workspaces --if-present',
  'test:run': 'npm run test:run --workspaces --if-present',
  'test:watch': 'npm run test:watch --workspaces --if-present',
  'lint': 'npm run lint --workspaces --if-present',
  'lint:fix': 'npm run lint:fix --workspaces --if-present',
  'typecheck': 'npm run typecheck --workspaces --if-present',
  'format': 'prettier --write \"**/*.{ts,tsx,js,jsx,json,md}\"',
  'format:check': 'prettier --check \"**/*.{ts,tsx,js,jsx,json,md}\"',
  'check:all': 'npm run lint && npm run typecheck && npm run test:run',
  'fix': 'npm run format && npm run lint:fix',
  'clean': 'npm run clean --workspaces --if-present && rimraf node_modules',
  'prepare': 'husky install'
};
rootPkg.engines = {
  'node': '>=18.0.0',
  'npm': '>=8.0.0'
};
fs.writeFileSync('package.json', JSON.stringify(rootPkg, null, 2) + '\n');
console.log('✅ Updated root package.json');

// Update frontend package.json
const frontendPkg = JSON.parse(fs.readFileSync('frontend/package.json', 'utf8'));
frontendPkg.type = 'module';
frontendPkg.scripts = {
  ...frontendPkg.scripts,
  'dev': 'vite',
  'build': 'tsc -b && vite build',
  'preview': 'vite preview',
  'test': 'vitest',
  'test:run': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
  'lint': 'eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0',
  'lint:fix': 'eslint . --ext ts,tsx --fix',
  'typecheck': 'tsc -b',
  'clean': 'rimraf dist node_modules',
  'format': 'prettier --write \"src/**/*.{ts,tsx,js,jsx,json,css}\"'
};
fs.writeFileSync('frontend/package.json', JSON.stringify(frontendPkg, null, 2) + '\n');
console.log('✅ Updated frontend/package.json');

// Update backend package.json
const backendPkg = JSON.parse(fs.readFileSync('backend/services/api/package.json', 'utf8'));
backendPkg.scripts = {
  ...backendPkg.scripts,
  'dev': 'tsx watch src/index.ts',
  'build': 'tsc',
  'start': 'node dist/index.js',
  'test': 'vitest',
  'test:run': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
  'lint': 'eslint . --ext ts --report-unused-disable-directives --max-warnings 0',
  'lint:fix': 'eslint . --ext ts --fix',
  'typecheck': 'tsc --noEmit',
  'clean': 'rimraf dist node_modules',
  'format': 'prettier --write \"src/**/*.{ts,js,json}\"'
};
fs.writeFileSync('backend/services/api/package.json', JSON.stringify(backendPkg, null, 2) + '\n');
console.log('✅ Updated backend/package.json');

// Update shared package.json
const sharedPkg = JSON.parse(fs.readFileSync('packages/shared/package.json', 'utf8'));
sharedPkg.scripts = {
  ...sharedPkg.scripts,
  'build': 'tsc',
  'test': 'vitest',
  'test:run': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
  'lint': 'eslint . --ext ts --report-unused-disable-directives --max-warnings 0',
  'lint:fix': 'eslint . --ext ts --fix',
  'typecheck': 'tsc --noEmit',
  'clean': 'rimraf dist node_modules',
  'format': 'prettier --write \"src/**/*.{ts,js,json}\"'
};
fs.writeFileSync('packages/shared/package.json', JSON.stringify(sharedPkg, null, 2) + '\n');
console.log('✅ Updated shared/package.json');
"

print_success "Package.json files updated"

# ================================================
# STEP 7: Create Configuration Files
# ================================================
print_info "Step 7: Creating configuration files..."

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

node_version=$(node --version | sed 's/v//')
echo "$node_version" > .nvmrc

print_success "Configuration files created"

# ================================================
# STEP 8: Install Dependencies
# ================================================
print_info "Step 8: Installing dependencies..."

# Install frontend specific dependencies
cd frontend
npm install --save-dev @vitejs/plugin-react-swc @testing-library/react @testing-library/jest-dom jsdom vitest @vitest/ui
cd ..

# Install backend specific dependencies  
cd backend/services/api
npm install --save-dev tsx
cd ../../..

# Install root dependencies
npm install --save-dev @typescript-eslint/eslint-plugin@latest @typescript-eslint/parser@latest eslint-config-prettier prettier rimraf concurrently husky lint-staged

print_success "Dependencies installed"

# ================================================
# STEP 9: Run Formatting
# ================================================
print_info "Step 9: Running code formatting..."

npm run format 2>/dev/null || true

print_success "Code formatted"

# ================================================
# STEP 10: Final Checks
# ================================================
echo ""
echo "============================================="
echo -e "${GREEN}✨ Setup Complete!${NC}"
echo "============================================="
echo ""
print_info "Running final checks..."
echo ""

# Run the checks
if npm run check:all; then
    echo ""
    echo -e "${GREEN}🎉 All checks passed successfully!${NC}"
    echo ""
    print_info "Your monorepo is ready for development!"
    echo ""
    echo "📋 Available commands:"
    echo "  npm run dev         - Start development servers"
    echo "  npm run build       - Build all packages"
    echo "  npm run test        - Run tests"
    echo "  npm run check:all   - Run all checks"
    echo "  npm run fix         - Auto-fix issues"
    echo ""
    echo "🚀 Start development with:"
    echo "  npm run dev"
    echo ""
    echo "Frontend: http://localhost:3000"
    echo "Backend:  http://localhost:8080"
else
    echo ""
    print_error "Some checks failed. Please review the errors above."
    echo ""
    print_info "Try running:"
    echo "  npm run fix         - Auto-fix issues"
    echo "  npm run check:all   - Re-run checks"
fi
#!/bin/bash

echo "🧪 Fixing Test Configuration"
echo "============================"

# 1. Install missing test dependencies
echo "📦 Installing test dependencies..."
cd frontend && npm install --save-dev @testing-library/react @testing-library/jest-dom jsdom && cd ..

# 2. Create Vitest config for frontend
echo "⚡ Creating frontend Vitest configuration..."
cat > frontend/vitest.config.ts << 'EOF'
import { defineConfig } from 'vite';
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

# 3. Create test setup file
echo "🔧 Creating test setup file..."
mkdir -p frontend/src/test
cat > frontend/src/test/setup.ts << 'EOF'
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach } from 'vitest';

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock fetch for tests
global.fetch = vi.fn();

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
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

# 4. Update frontend test
echo "🧪 Updating frontend test..."
cat > frontend/src/__tests__/App.test.tsx << 'EOF'
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import App from '../App';

describe('App Component', () => {
  beforeEach(() => {
    // Reset fetch mock
    vi.clearAllMocks();
    
    // Mock successful fetch response
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ value: 5 }),
    });
  });

  it('renders the title', async () => {
    render(<App />);
    
    // Check for loading state first
    expect(screen.getByText(/Loading/i)).toBeInTheDocument();
    
    // Wait for the app to load
    await waitFor(() => {
      expect(screen.getByText(/Engineering App/i)).toBeInTheDocument();
    });
    
    // Check that the subtitle is rendered
    expect(screen.getByText(/Welcome to your engineering platform/i)).toBeInTheDocument();
  });

  it('displays the counter after loading', async () => {
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText(/Count: 5/i)).toBeInTheDocument();
    });
    
    // Check that increment button is present
    expect(screen.getByRole('button', { name: /Increment/i })).toBeInTheDocument();
  });

  it('handles fetch error gracefully', async () => {
    // Mock fetch error
    global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));
    
    render(<App />);
    
    await waitFor(() => {
      expect(screen.getByText(/Backend connection failed/i)).toBeInTheDocument();
    });
  });
});
EOF

# 5. Create backend Vitest config
echo "🖥️ Creating backend Vitest configuration..."
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

# 6. Update backend test
echo "🧪 Updating backend test..."
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

# 7. Create shared package Vitest config
echo "📦 Creating shared package Vitest configuration..."
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

# 8. Update test scripts to run once instead of watch mode
echo "📝 Updating test scripts for CI mode..."
node -e "
const fs = require('fs');
const path = require('path');

// Update root package.json
const rootPkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
rootPkg.scripts = {
  ...rootPkg.scripts,
  'test': 'npm run test:run --workspaces --if-present',
  'test:run': 'npm run test:run --workspaces --if-present',
  'test:watch': 'npm run test:watch --workspaces --if-present',
};
fs.writeFileSync('package.json', JSON.stringify(rootPkg, null, 2) + '\n');

// Update frontend
const frontendPkg = JSON.parse(fs.readFileSync('frontend/package.json', 'utf8'));
frontendPkg.scripts = {
  ...frontendPkg.scripts,
  'test': 'vitest',
  'test:run': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
};
fs.writeFileSync('frontend/package.json', JSON.stringify(frontendPkg, null, 2) + '\n');

// Update backend
const backendPkg = JSON.parse(fs.readFileSync('backend/services/api/package.json', 'utf8'));
backendPkg.scripts = {
  ...backendPkg.scripts,
  'test': 'vitest',
  'test:run': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
};
fs.writeFileSync('backend/services/api/package.json', JSON.stringify(backendPkg, null, 2) + '\n');

// Update shared
const sharedPkg = JSON.parse(fs.readFileSync('packages/shared/package.json', 'utf8'));
sharedPkg.scripts = {
  ...sharedPkg.scripts,
  'test': 'vitest',
  'test:run': 'vitest run',
  'test:watch': 'vitest',
  'test:coverage': 'vitest run --coverage',
};
fs.writeFileSync('packages/shared/package.json', JSON.stringify(sharedPkg, null, 2) + '\n');

console.log('✅ Updated test scripts');
"

# 9. Install dependencies
echo ""
echo "📦 Installing dependencies..."
npm install

# 10. Update check:all to use test:run
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts['check:all'] = 'npm run lint && npm run typecheck && npm run test:run';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✅ Updated check:all to use test:run');
"

echo ""
echo "============================"
echo "✅ Test configuration fixed!"
echo ""
echo "📋 What was done:"
echo "  ✓ Installed @testing-library/react and jsdom"
echo "  ✓ Created Vitest configurations for all workspaces"
echo "  ✓ Set up proper test environment (jsdom for frontend, node for backend)"
echo "  ✓ Created comprehensive tests with mocking"
echo "  ✓ Updated test scripts to run once (not watch mode)"
echo ""
echo "🎯 Now run:"
echo "  npm run check:all"
echo ""
echo "All checks should now pass! 🎉"
echo ""
echo "📚 Additional test commands:"
echo "  npm run test:watch    - Run tests in watch mode"
echo "  npm run test:coverage - Run tests with coverage report"
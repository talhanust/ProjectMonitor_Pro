#!/bin/bash

echo "🔧 Fixing Vitest Imports"
echo "========================"

# 1. Fix the test setup file with proper imports
echo "📝 Fixing frontend/src/test/setup.ts..."
cat > frontend/src/test/setup.ts << 'EOF'
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock fetch for tests
global.fetch = vi.fn();

// Mock window.matchMedia
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

# 2. Update frontend tsconfig to include test files
echo "📝 Updating frontend/tsconfig.json to include test files..."
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

# 3. Install vitest types if not already installed
echo "📦 Ensuring vitest is installed..."
cd frontend && npm install --save-dev vitest @vitest/ui && cd ..

# 4. Create a simple test setup without complex mocking if the above still fails
echo "📝 Creating alternative simple setup file..."
cat > frontend/src/test/setup-simple.ts << 'EOF'
import '@testing-library/jest-dom';
EOF

# 5. Update vitest config to handle both setups
echo "⚡ Updating vitest.config.ts..."
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

# 6. Also ensure backend tests don't have similar issues
echo "🖥️ Checking backend test imports..."
if [ -f "backend/services/api/src/__tests__/server.test.ts" ]; then
  # Ensure vi is imported in backend tests if used
  sed -i "1s/^/import { vi } from 'vitest';\n/" backend/services/api/src/__tests__/server.test.ts 2>/dev/null || \
  sed -i '' "1s/^/import { vi } from 'vitest';\n/" backend/services/api/src/__tests__/server.test.ts 2>/dev/null || true
fi

echo ""
echo "========================"
echo "✅ Vitest imports fixed!"
echo ""
echo "🎯 Now run:"
echo "  npm run check:all"
echo ""
echo "This should resolve the TypeScript errors with 'vi' not being found."
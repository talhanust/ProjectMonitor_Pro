#!/bin/bash

echo "🔧 Fixing Frontend TypeScript Configuration"
echo "=========================================="

# 1. Clean any old build artifacts
echo "🧹 Cleaning old build artifacts..."
rm -f frontend/vite.config.d.ts
rm -f frontend/vite.config.d.ts.map
rm -rf frontend/dist
rm -f frontend/tsconfig.tsbuildinfo
rm -f frontend/tsconfig.node.tsbuildinfo

# 2. Update frontend tsconfig.json with proper configuration
echo "📝 Updating frontend/tsconfig.json..."
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,

    /* Path mapping */
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@utils/*": ["./src/utils/*"],
      "@hooks/*": ["./src/hooks/*"],
      "@types/*": ["./src/types/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# 3. Update tsconfig.node.json for vite config
echo "📝 Updating frontend/tsconfig.node.json..."
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

# 4. Create a separate tsconfig for build if needed
echo "📝 Creating frontend/tsconfig.app.json..."
cat > frontend/tsconfig.app.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,

    /* Path mapping */
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@utils/*": ["./src/utils/*"],
      "@hooks/*": ["./src/hooks/*"],
      "@types/*": ["./src/types/*"]
    }
  },
  "include": ["src"]
}
EOF

# 5. Update the typecheck script to use the correct config
echo "🔧 Updating frontend typecheck script..."
node -e "
const fs = require('fs');
const path = require('path');
const pkgPath = path.join('frontend', 'package.json');
if (fs.existsSync(pkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
  pkg.scripts = {
    ...pkg.scripts,
    'typecheck': 'tsc -b'
  };
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
  console.log('✅ Updated frontend typecheck script');
}
"

# 6. Ensure vite.config.ts has proper types
echo "⚡ Ensuring vite.config.ts is properly typed..."
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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

echo ""
echo "=========================================="
echo "✅ Frontend TypeScript configuration fixed!"
echo ""
echo "📋 What was done:"
echo "  ✓ Cleaned old build artifacts"
echo "  ✓ Separated vite.config.ts into its own tsconfig.node.json"
echo "  ✓ Created proper TypeScript project references"
echo "  ✓ Updated typecheck script to use 'tsc -b'"
echo ""
echo "🎯 Now run:"
echo "  npm run check:all"
echo ""
echo "All checks should now pass! 🎉"
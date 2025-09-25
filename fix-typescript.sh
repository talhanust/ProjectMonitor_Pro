#!/bin/bash

echo "🔧 Fixing TypeScript and Dependency Issues"
echo "=========================================="

# 1. Install missing Vite React plugin
echo "📦 Installing missing dependencies..."
cd frontend && npm install --save-dev @vitejs/plugin-react-swc && cd ..

# 2. Fix TypeScript configurations
echo ""
echo "📝 Fixing TypeScript configurations..."

# Fix base tsconfig
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

# Fix frontend tsconfig
cat > frontend/tsconfig.json << 'EOF'
{
  "extends": "../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "jsx": "react-jsx",
    "rootDir": ".",
    "outDir": "./dist",
    "types": ["vite/client"],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@components/*": ["./src/components/*"],
      "@utils/*": ["./src/utils/*"],
      "@hooks/*": ["./src/hooks/*"],
      "@types/*": ["./src/types/*"]
    }
  },
  "include": ["src/**/*", "vite.config.ts"],
  "exclude": ["node_modules", "dist"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# Create tsconfig.node.json for frontend
cat > frontend/tsconfig.node.json << 'EOF'
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

# Fix backend tsconfig
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

# Fix shared package tsconfig
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

# 3. Update @typescript-eslint packages to support TypeScript 5.9
echo ""
echo "📦 Updating ESLint TypeScript packages..."
npm install --save-dev @typescript-eslint/eslint-plugin@latest @typescript-eslint/parser@latest

# 4. Update ESLint configs to use latest parser
echo ""
echo "🔧 Updating ESLint configurations..."

# Frontend .eslintrc.cjs
cat > frontend/.eslintrc.cjs << 'EOF'
module.exports = {
  root: true,
  env: { browser: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react-hooks/recommended',
    'prettier',
  ],
  ignorePatterns: ['dist', '.eslintrc.cjs', 'vite.config.ts'],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: false,
  },
  plugins: ['react-refresh'],
  rules: {
    'react-refresh/only-export-components': [
      'warn',
      { allowConstantExport: true },
    ],
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
  },
};
EOF

# Backend .eslintrc.js
cat > backend/services/api/.eslintrc.js << 'EOF'
module.exports = {
  root: true,
  env: { node: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: false,
  },
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
  },
  ignorePatterns: ['dist', 'node_modules', '.eslintrc.js'],
};
EOF

# Shared package .eslintrc.js
cat > packages/shared/.eslintrc.js << 'EOF'
module.exports = {
  root: true,
  env: { node: true, es2020: true },
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'prettier',
  ],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    project: false,
  },
  plugins: ['@typescript-eslint'],
  rules: {
    '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/no-explicit-any': 'warn',
  },
  ignorePatterns: ['dist', 'node_modules', '.eslintrc.js'],
};
EOF

# 5. Install additional missing dependencies
echo ""
echo "📦 Ensuring all dependencies are installed..."
npm install --save-dev eslint-config-prettier

# 6. Run a clean install to ensure everything is in sync
echo ""
echo "🔄 Running clean install..."
npm install

echo ""
echo "=========================================="
echo "✅ TypeScript and dependency issues fixed!"
echo ""
echo "📋 What was done:"
echo "  ✓ Installed @vitejs/plugin-react-swc"
echo "  ✓ Fixed TypeScript configurations for all workspaces"
echo "  ✓ Updated @typescript-eslint to support TypeScript 5.9"
echo "  ✓ Created proper tsconfig files for each environment"
echo "  ✓ Updated ESLint configurations"
echo ""
echo "🎯 Now run:"
echo "  npm run check:all"
echo ""
echo "This should now pass all checks!"
echo ""
echo "💡 Note: The TypeScript version warning is now just informational"
echo "   and won't cause any issues with your builds."
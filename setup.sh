#!/bin/bash

# Create monorepo directory structure for engineering application
# Run this script in your project root directory

echo "🚀 Setting up monorepo directory structure..."

# Create main directories
mkdir -p frontend/src/{components,hooks,utils,services,types,assets,pages,layouts,contexts,stores}
mkdir -p frontend/public
mkdir -p backend/services/api/src/{controllers,services,models,middleware,utils,types,config,routes,validators}
mkdir -p backend/services/api/prisma
mkdir -p packages/shared/src/{types,utils,constants}
mkdir -p packages/ui/src
mkdir -p packages/config/src
mkdir -p docs/{adr,api,guides}
mkdir -p scripts/{build,deploy}
mkdir -p tools
mkdir -p .github/workflows
mkdir -p .vscode
mkdir -p .husky

# Create placeholder index files for shared package
cat > packages/shared/src/index.ts << 'EOF'
// Main entry point for shared package
export * from './types';
export * from './utils';
export * from './constants';
EOF

cat > packages/shared/src/types/index.ts << 'EOF'
// Shared type definitions
export interface BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

export type ApiResponse<T> = {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
};
EOF

cat > packages/shared/src/utils/index.ts << 'EOF'
// Shared utility functions
export const formatDate = (date: Date): string => {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date);
};

export const sleep = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};
EOF

cat > packages/shared/src/constants/index.ts << 'EOF'
// Shared constants
export const API_VERSION = 'v1';
export const DEFAULT_PAGE_SIZE = 20;
export const MAX_PAGE_SIZE = 100;

export enum ErrorCode {
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',
  NOT_FOUND = 'NOT_FOUND',
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  INTERNAL_ERROR = 'INTERNAL_ERROR',
}
EOF

# Create tsup config for shared package
cat > packages/shared/tsup.config.ts << 'EOF'
import { defineConfig } from 'tsup';

export default defineConfig({
  entry: {
    index: 'src/index.ts',
    types: 'src/types/index.ts',
    utils: 'src/utils/index.ts',
    constants: 'src/constants/index.ts',
  },
  format: ['cjs', 'esm'],
  dts: true,
  splitting: false,
  sourcemap: true,
  clean: true,
  treeshake: true,
  minify: false,
});
EOF

# Create shared package tsconfig
cat > packages/shared/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src",
    "composite": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts", "**/*.spec.ts"]
}
EOF

# Create frontend entry point
cat > frontend/src/main.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
EOF

cat > frontend/src/App.tsx << 'EOF'
import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-md">
        <h1 className="text-3xl font-bold text-gray-800 mb-4">
          Engineering App
        </h1>
        <p className="text-gray-600 mb-4">
          Welcome to your engineering platform
        </p>
        <button
          className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
          onClick={() => setCount((count) => count + 1)}
        >
          Count: {count}
        </button>
      </div>
    </div>
  );
}

export default App;
EOF

cat > frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

cat > frontend/src/vite-env.d.ts << 'EOF'
/// <reference types="vite/client" />
EOF

# Create frontend index.html
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Engineering App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# Create Vite config
cat > frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';
import path from 'path';

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
});
EOF

# Create Tailwind config
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

cat > frontend/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# Create backend API entry point
cat > backend/services/api/src/index.ts << 'EOF'
import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';
import { config } from './config/env';
import { logger } from './utils/logger';

const server = Fastify({
  logger,
});

async function bootstrap() {
  try {
    // Register plugins
    await server.register(helmet);
    await server.register(cors, {
      origin: config.CORS_ORIGIN,
      credentials: true,
    });
    await server.register(rateLimit, {
      max: 100,
      timeWindow: '1 minute',
    });

    // Health check route
    server.get('/health', async () => {
      return { status: 'ok', timestamp: new Date().toISOString() };
    });

    // Start server
    await server.listen({ port: config.PORT, host: '0.0.0.0' });
    console.log(`🚀 Server running at http://localhost:${config.PORT}`);
  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

bootstrap();
EOF

# Create backend config
cat > backend/services/api/src/config/env.ts << 'EOF'
import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().default('8080').transform(Number),
  DATABASE_URL: z.string().default('postgresql://localhost:5432/engineering_app'),
  JWT_SECRET: z.string().default('your-secret-key-change-in-production'),
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
});

export const config = envSchema.parse(process.env);
EOF

# Create logger utility
cat > backend/services/api/src/utils/logger.ts << 'EOF'
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      translateTime: 'HH:MM:ss Z',
      ignore: 'pid,hostname',
    },
  },
});
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Environment
NODE_ENV=development

# Frontend
VITE_API_URL=http://localhost:8080

# Backend
PORT=8080
DATABASE_URL=postgresql://user:password@localhost:5432/engineering_app
JWT_SECRET=your-secret-key-change-in-production
CORS_ORIGIN=http://localhost:3000

# Database
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=engineering_app
EOF

# Create Prettier config
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

# Create ESLint config
cat > .eslintrc.json << 'EOF'
{
  "root": true,
  "env": {
    "browser": true,
    "es2022": true,
    "node": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:prettier/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "plugins": ["@typescript-eslint", "prettier"],
  "rules": {
    "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    "@typescript-eslint/no-explicit-any": "warn",
    "@typescript-eslint/explicit-function-return-type": "off",
    "@typescript-eslint/explicit-module-boundary-types": "off",
    "prettier/prettier": "error"
  },
  "ignorePatterns": ["dist", "build", "node_modules", "coverage"]
}
EOF

# Create VS Code settings
cat > .vscode/settings.json << 'EOF'
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "files.exclude": {
    "**/node_modules": true,
    "**/dist": true,
    "**/build": true,
    "**/.turbo": true
  }
}
EOF

# Create VS Code extensions recommendations
cat > .vscode/extensions.json << 'EOF'
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "prisma.prisma",
    "mikestead.dotenv",
    "christian-kohler.path-intellisense",
    "streetsidesoftware.code-spell-checker"
  ]
}
EOF

# Create husky pre-commit hook
cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npx lint-staged
EOF

chmod +x .husky/pre-commit

echo "✅ Directory structure created successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Run 'npm install' at the root to install all dependencies"
echo "2. Copy .env.example to .env and configure your environment variables"
echo "3. Set up your database (if using Prisma, run 'npm run migrate -w @backend/api')"
echo "4. Run 'npm run dev' to start all services in development mode"
echo ""
echo "🎉 Happy coding!"

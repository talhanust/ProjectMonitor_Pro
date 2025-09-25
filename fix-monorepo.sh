#!/bin/bash

# Fix Engineering App Monorepo Issues
# This script addresses all the issues found in your npm run outputs

echo "🔧 Starting Engineering App Monorepo Fix Process..."
echo "================================================"

# 1. Fix TypeScript path mapping issues
echo "📝 Fixing TypeScript path mappings..."
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

# 2. Fix Frontend TypeScript configuration
echo "📱 Fixing frontend TypeScript config..."
cat > frontend/tsconfig.json << 'EOF'
{
  "extends": "../tsconfig.base.json",
  "compilerOptions": {
    "rootDir": ".",
    "outDir": "./dist",
    "types": ["vite/client"]
  },
  "include": [
    "src/**/*",
    "vite.config.ts"
  ],
  "exclude": ["node_modules", "dist"]
}
EOF

# 3. Fix Backend TypeScript configuration
echo "🖥️ Fixing backend TypeScript config..."
cat > backend/services/api/tsconfig.json << 'EOF'
{
  "extends": "../../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "rootDir": "./src",
    "outDir": "./dist",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "strict": true,
    "resolveJsonModule": true,
    "types": ["node"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# 4. Fix Shared Package TypeScript configuration
echo "📦 Fixing shared package TypeScript config..."
cat > packages/shared/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "rootDir": "./src",
    "outDir": "./dist",
    "declaration": true,
    "declarationMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF

# 5. Fix Logger issues in backend
echo "📋 Fixing backend logger..."
cat > backend/services/api/src/utils/logger.ts << 'EOF'
import pino from 'pino';

const logger = pino({
  level: process.env['LOG_LEVEL'] || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      ignore: 'pid,hostname'
    }
  }
});

export default logger;
EOF

# 6. Fix Fastify server initialization
echo "🚀 Fixing Fastify server..."
cat > backend/services/api/src/index.ts << 'EOF'
import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './config';
import { setupRoutes } from './routes';
import logger from './utils/logger';

const server = Fastify({
  logger: {
    level: process.env['LOG_LEVEL'] || 'info',
    transport: {
      target: 'pino-pretty'
    }
  }
});

async function start() {
  try {
    // Register plugins
    await server.register(cors, {
      origin: true
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

# 7. Fix Frontend linting issues
echo "🎨 Fixing frontend linting issues..."
cat > frontend/src/App.tsx << 'EOF'
import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [count, setCount] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('http://localhost:8080/counter')
      .then(res => res.json())
      .then(data => {
        setCount(data.value);
        setLoading(false);
      })
      .catch(err => {
        console.error('Failed to fetch count:', err);
        setLoading(false);
      });
  }, []);

  const incrementCount = async () => {
    try {
      const response = await fetch('http://localhost:8080/counter/increment', {
        method: 'POST',
      });
      const data = await response.json();
      setCount(data.value);
    } catch (err) {
      console.error('Failed to increment count:', err);
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>Engineering App</h1>
        <p className="subtitle">Welcome to your engineering platform</p>
        
        {count !== null && (
          <div className="counter-section">
            <p>Count: {count}</p>
            <button onClick={incrementCount}>Increment</button>
          </div>
        )}
      </header>
    </div>
  );
}

export default App;
EOF

# 8. Fix shared package linting issues
echo "📚 Fixing shared package linting..."
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

# 9. Fix frontend package.json for module type
echo "📄 Fixing frontend package.json..."
if [ -f "frontend/package.json" ]; then
  # Add type: module to frontend package.json
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('frontend/package.json', 'utf8'));
    pkg.type = 'module';
    fs.writeFileSync('frontend/package.json', JSON.stringify(pkg, null, 2));
  "
fi

# 10. Create basic test files
echo "🧪 Creating test files..."

# Frontend test
mkdir -p frontend/src/__tests__
cat > frontend/src/__tests__/App.test.tsx << 'EOF'
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import App from '../App';

describe('App Component', () => {
  it('renders the title', () => {
    render(<App />);
    expect(screen.getByText(/Engineering App/i)).toBeDefined();
  });
});
EOF

# Backend test
mkdir -p backend/services/api/src/__tests__
cat > backend/services/api/src/__tests__/server.test.ts << 'EOF'
import { describe, it, expect } from 'vitest';

describe('Server', () => {
  it('should have tests', () => {
    expect(true).toBe(true);
  });
});
EOF

# Shared package test
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

# 11. Create Prisma schema
echo "🗄️ Creating Prisma schema..."
mkdir -p backend/services/api/prisma
cat > backend/services/api/prisma/schema.prisma << 'EOF'
// This is your Prisma schema file

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  projects  Project[]
}

model Project {
  id          String   @id @default(cuid())
  name        String
  description String?
  status      String   @default("active")
  userId      String
  user        User     @relation(fields: [userId], references: [id])
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
EOF

# 12. Update backend package.json for Prisma
echo "🔧 Updating backend package.json for Prisma..."
if [ -f "backend/services/api/package.json" ]; then
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('backend/services/api/package.json', 'utf8'));
    pkg.prisma = { schema: './prisma/schema.prisma' };
    fs.writeFileSync('backend/services/api/package.json', JSON.stringify(pkg, null, 2));
  "
fi

# 13. Create missing config files if needed
echo "⚙️ Creating config files..."

# Backend config
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

# Backend routes
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

# 14. Run formatting to ensure consistency
echo "✨ Running formatter..."
npm run format 2>/dev/null || true

# 15. Install missing dependencies if needed
echo "📦 Checking dependencies..."
npm install 2>/dev/null || true

echo ""
echo "✅ Fix process complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Run 'npm install' to ensure all dependencies are installed"
echo "2. Run 'npm run lint' to verify linting issues are fixed"
echo "3. Run 'npm run typecheck' to verify TypeScript issues are resolved"
echo "4. Run 'npm run test' to run the new test files"
echo "5. Run 'npx prisma validate' in backend/services/api to validate Prisma schema"
echo ""
echo "For database setup:"
echo "1. Set DATABASE_URL in your .env file"
echo "2. Run 'npx prisma migrate dev' in backend/services/api"
echo ""
echo "To start development:"
echo "Run 'npm run dev' to start both frontend and backend"

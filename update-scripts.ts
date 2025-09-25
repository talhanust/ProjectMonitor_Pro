#!/usr/bin/env node

/**
 * Script to update the root package.json with comprehensive npm scripts
 * for the engineering app monorepo
 */

import fs from 'fs';
import path from 'path';

// Define the comprehensive scripts configuration
const scriptsToAdd = {
  // Development scripts
  dev: 'npm run dev:backend & npm run dev:frontend',
  'dev:frontend': 'npm run dev -w frontend',
  'dev:backend': 'npm run dev -w @backend/api',
  'dev:all': 'concurrently "npm run dev:backend" "npm run dev:frontend"',

  // Build scripts
  build: 'npm run build:frontend && npm run build:backend',
  'build:frontend': 'npm run build -w frontend',
  'build:backend': 'npm run build -w @backend/api',
  'build:shared': 'npm run build -w @packages/shared',
  'build:all': 'npm run build:shared && npm run build',

  // Test scripts
  test: 'npm run test --workspaces --if-present',
  'test:frontend': 'npm run test -w frontend',
  'test:backend': 'npm run test -w @backend/api',
  'test:shared': 'npm run test -w @packages/shared',
  'test:watch': 'npm run test:watch --workspaces --if-present',
  'test:coverage': 'npm run test:coverage --workspaces --if-present',

  // Linting and formatting
  lint: 'npm run lint --workspaces --if-present',
  'lint:frontend': 'npm run lint -w frontend',
  'lint:backend': 'npm run lint -w @backend/api',
  'lint:shared': 'npm run lint -w @packages/shared',
  'lint:fix': 'npm run lint:fix --workspaces --if-present',
  format: 'prettier --write "**/*.{ts,tsx,js,jsx,json,md}"',
  'format:check': 'prettier --check "**/*.{ts,tsx,js,jsx,json,md}"',

  // Type checking
  typecheck: 'npm run typecheck --workspaces --if-present',
  'typecheck:frontend': 'npm run typecheck -w frontend',
  'typecheck:backend': 'npm run typecheck -w @backend/api',
  'typecheck:shared': 'npm run typecheck -w @packages/shared',

  // Combined check scripts
  'check:all': 'npm run lint && npm run typecheck && npm run test',
  'check:frontend': 'npm run lint:frontend && npm run typecheck:frontend && npm run test:frontend',
  'check:backend': 'npm run lint:backend && npm run typecheck:backend && npm run test:backend',
  'check:shared': 'npm run lint:shared && npm run typecheck:shared && npm run test:shared',
  'check:quick': 'npm run lint && npm run typecheck',

  // Database scripts
  'db:migrate': 'npm run db:migrate -w @backend/api',
  'db:generate': 'npm run db:generate -w @backend/api',
  'db:push': 'npm run db:push -w @backend/api',
  'db:studio': 'npm run db:studio -w @backend/api',
  'db:seed': 'npm run db:seed -w @backend/api',

  // Utility scripts
  clean: 'npm run clean --workspaces --if-present && rimraf node_modules',
  'clean:dist': 'rimraf "**/dist" "**/build" "**/.next"',
  'clean:all': 'npm run clean:dist && npm run clean',
  fresh: 'npm run clean:all && npm install && npm run build:all',
  prepare: 'husky install',
  postinstall: 'npm run build:shared',

  // CI/CD scripts
  'ci:test': 'npm run lint && npm run typecheck && npm run test -- --run',
  'ci:build': 'npm run build:all',
  precommit: 'lint-staged',
  prepush: 'npm run check:quick',

  // Start production
  start: 'npm run start:backend',
  'start:backend': 'npm run start -w @backend/api',
  'start:frontend': 'npm run preview -w frontend',

  // Docker scripts
  'docker:build': 'docker-compose build',
  'docker:up': 'docker-compose up',
  'docker:down': 'docker-compose down',
  'docker:logs': 'docker-compose logs -f',

  // Dependency management
  'deps:check': 'npm outdated',
  'deps:update': 'npm update --save',
  'deps:audit': 'npm audit',
  'deps:fix': 'npm audit fix',
};

// Update root package.json
function updatePackageJson() {
  const packageJsonPath = path.join(process.cwd(), 'package.json');

  try {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
    packageJson.scripts = { ...packageJson.scripts, ...scriptsToAdd };

    // Sort scripts alphabetically
    packageJson.scripts = Object.fromEntries(
      Object.entries(packageJson.scripts).sort(([a], [b]) => a.localeCompare(b)),
    );

    fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n', 'utf8');
    console.log('✅ Successfully updated root package.json');
  } catch (err) {
    console.error('❌ Error updating root package.json:', (err as Error).message);
    process.exit(1);
  }
}

// Update workspace package.json files
function updateWorkspacePackageJsons() {
  const workspaces = [
    {
      path: 'frontend/package.json',
      scripts: {
        dev: 'vite',
        build: 'tsc && vite build',
        preview: 'vite preview',
        test: 'vitest',
        'test:watch': 'vitest --watch',
        'test:coverage': 'vitest --coverage',
        lint: 'eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0',
        'lint:fix': 'eslint . --ext ts,tsx --fix',
        typecheck: 'tsc --noEmit',
        clean: 'rimraf dist node_modules',
      },
    },
    {
      path: 'backend/services/api/package.json',
      scripts: {
        dev: 'tsx watch src/index.ts',
        build: 'tsc',
        start: 'node dist/index.js',
        test: 'vitest',
        'test:watch': 'vitest --watch',
        'test:coverage': 'vitest --coverage',
        lint: 'eslint . --ext ts --report-unused-disable-directives --max-warnings 0',
        'lint:fix': 'eslint . --ext ts --fix',
        typecheck: 'tsc --noEmit',
        clean: 'rimraf dist node_modules',
        'db:generate': 'prisma generate',
        'db:migrate': 'prisma migrate dev',
        'db:push': 'prisma db push',
        'db:studio': 'prisma studio',
        'db:seed': 'tsx src/seed.ts',
      },
    },
    {
      path: 'packages/shared/package.json',
      scripts: {
        build: 'tsc',
        test: 'vitest',
        'test:watch': 'vitest --watch',
        'test:coverage': 'vitest --coverage',
        lint: 'eslint . --ext ts --report-unused-disable-directives --max-warnings 0',
        'lint:fix': 'eslint . --ext ts --fix',
        typecheck: 'tsc --noEmit',
        clean: 'rimraf dist node_modules',
      },
    },
  ];

  workspaces.forEach(({ path: pkgPath, scripts }) => {
    const fullPath = path.join(process.cwd(), pkgPath);
    if (!fs.existsSync(fullPath)) return;

    try {
      const packageJson = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
      packageJson.scripts = { ...packageJson.scripts, ...scripts };
      fs.writeFileSync(fullPath, JSON.stringify(packageJson, null, 2) + '\n', 'utf8');
      console.log(`✅ Updated ${pkgPath}`);
    } catch (err) {
      console.warn(`⚠️ Could not update ${pkgPath}: ${(err as Error).message}`);
    }
  });
}

// Run updates
console.log('🔧 Updating package.json files...\n');
updatePackageJson();
updateWorkspacePackageJsons();
console.log('\n✨ Done! Your monorepo scripts are up-to-date.');

#!/usr/bin/env tsx
/**
 * fix-server-and-frontend.ts
 * Script to fix backend routes and frontend Tailwind config
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🔧 Fixing backend routes and frontend Tailwind config...');

// ====== 1. Backend: Fastify server fixes ======
const backendIndexFile = path.join(__dirname, 'backend/services/api/src/index.ts');

if (fs.existsSync(backendIndexFile)) {
  let content = fs.readFileSync(backendIndexFile, 'utf-8');

  // Ensure root GET route exists
  if (!content.includes("server.get('/', async")) {
    const rootRoute = `
server.get('/', async () => {
  return { message: '🚀 Welcome to Project Monitor Pro API!', docs: '/docs', health: '/health' };
});
`;
    content = content.replace(
      /async function bootstrap\(\) {/,
      `async function bootstrap() {\n    // Added root route\n${rootRoute}`,
    );
    fs.writeFileSync(backendIndexFile, content, 'utf-8');
    console.log('✅ Added root GET route "/"');
  }

  // Suggest adding body parsing fix
  console.log(
    '⚠️ Make sure POST /counter/increment requests include a JSON body: e.g., fetch(..., { body: JSON.stringify({}) })',
  );
}

// ====== 2. Frontend: Tailwind config fix ======
const tailwindConfigFile = path.join(__dirname, 'frontend/tailwind.config.js');

if (fs.existsSync(tailwindConfigFile)) {
  let configContent = fs.readFileSync(tailwindConfigFile, 'utf-8');

  if (!/content:/.test(configContent)) {
    configContent = `
module.exports = {
  content: ["./src/**/*.{ts,tsx,js,jsx}"],
  theme: { extend: {} },
  plugins: [],
};
`;
    fs.writeFileSync(tailwindConfigFile, configContent, 'utf-8');
    console.log('✅ Fixed Tailwind content paths');
  } else {
    console.log('ℹ️ Tailwind content paths already configured');
  }
}

console.log('✨ Backend and frontend fixes applied successfully!');

// fix-counter-endpoints.js
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('🔧 Fixing backend parser, frontend requests, and Tailwind config...');

// ----------------------
// Backend Fix (Fastify JSON parser)
// ----------------------
const backendIndex = path.join(__dirname, 'backend/services/api/src/index.ts');

if (fs.existsSync(backendIndex)) {
  let content = fs.readFileSync(backendIndex, 'utf-8');

  if (!content.includes("addContentTypeParser('application/json'")) {
    content = content.replace(
      /(const\s+app\s*=\s*fastify\([^)]*\);?)/,
      `$1\n\n// Allow empty JSON bodies\napp.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {\n  try {\n    const json = body.length === 0 ? {} : JSON.parse(body);\n    done(null, json);\n  } catch (err) {\n    err.statusCode = 400;\n    done(err, undefined);\n  }\n});`,
    );

    fs.writeFileSync(backendIndex, content, 'utf-8');
    console.log('✅ Backend JSON parser fix applied');
  } else {
    console.log('ℹ️ Backend parser already patched');
  }
} else {
  console.log('⚠️ Backend index.ts not found, skipping');
}

// ----------------------
// Frontend Fix (/counter/increment POST)
// ----------------------
const frontendSrc = path.join(__dirname, 'frontend/src');
function fixFrontendRequests(dir) {
  const files = fs.readdirSync(dir);
  for (const f of files) {
    const full = path.join(dir, f);
    if (fs.statSync(full).isDirectory()) {
      fixFrontendRequests(full);
    } else if (/\.(t|j)sx?$/.test(f)) {
      let code = fs.readFileSync(full, 'utf-8');
      if (code.includes('/counter/increment') && !code.includes('JSON.stringify({')) {
        code = code.replace(
          /(fetch\([^)]*\/counter\/increment[^}]+)({[^}]*})?\)/,
          `fetch('http://localhost:8080/counter/increment', {\n  method: 'POST',\n  headers: { 'Content-Type': 'application/json' },\n  body: JSON.stringify({})\n})`,
        );
        fs.writeFileSync(full, code, 'utf-8');
        console.log(`✅ Patched frontend request in ${full}`);
      }
    }
  }
}
if (fs.existsSync(frontendSrc)) {
  fixFrontendRequests(frontendSrc);
} else {
  console.log('⚠️ Frontend src/ not found, skipping');
}

// ----------------------
// Tailwind Fix
// ----------------------
const tailwindConfig = path.join(__dirname, 'frontend/tailwind.config.js');

if (fs.existsSync(tailwindConfig)) {
  let tw = fs.readFileSync(tailwindConfig, 'utf-8');
  if (!tw.includes('./src/**/*.{js,ts,jsx,tsx}')) {
    tw = tw.replace(
      /content:\s*\[[^\]]*\]/,
      `content: [\n    './index.html',\n    './src/**/*.{js,ts,jsx,tsx}',\n    '../packages/shared/src/**/*.{js,ts,jsx,tsx}'\n  ]`,
    );
    fs.writeFileSync(tailwindConfig, tw, 'utf-8');
    console.log('✅ Tailwind config patched');
  } else {
    console.log('ℹ️ Tailwind already configured');
  }
} else {
  console.log('⚠️ Tailwind config not found, skipping');
}

console.log('✨ All fixes applied. Restart your backend and frontend dev servers!');

#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

console.log('🔧 Fixing backend parser and frontend request...');

const backendFile = path.join('backend', 'services', 'api', 'src', 'index.ts');
const frontendFile = path.join('frontend', 'src', 'App.tsx');

// --- Fix backend parser ---
let backendCode = fs.readFileSync(backendFile, 'utf8');
if (!backendCode.includes("app.addContentTypeParser('application/json'")) {
  backendCode = backendCode.replace(
    /const\s+app\s*=\s*fastify\([^)]*\);/,
    (match) => `${match}

// Added by fix-counter-body.ts
app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
  try {
    const json = body.length === 0 ? {} : JSON.parse(body);
    done(null, json);
  } catch (err) {
    err.statusCode = 400;
    done(err, undefined);
  }
});
`,
  );
  fs.writeFileSync(backendFile, backendCode, 'utf8');
  console.log('✅ Backend parser patch applied');
} else {
  console.log('ℹ️ Backend parser patch already present');
}

// --- Fix frontend request ---
let frontendCode = fs.readFileSync(frontendFile, 'utf8');
if (frontendCode.includes('fetch(') && !frontendCode.includes('JSON.stringify({})')) {
  frontendCode = frontendCode.replace(
    /fetch\([^)]*counter\/increment[^)]*\{([\s\S]*?)\})/,
    (match) =>
      match.replace(/headers:\s*\{[^}]*\}/, (headers) => `${headers},\n  body: JSON.stringify({})`),
  );
  fs.writeFileSync(frontendFile, frontendCode, 'utf8');
  console.log('✅ Frontend request body patch applied');
} else {
  console.log('ℹ️ Frontend already patched');
}

console.log('✨ All fixes applied. Restart backend & frontend servers.');

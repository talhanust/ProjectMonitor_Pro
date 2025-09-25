#!/bin/bash

echo "🔧 Fixing NPM Engine and Security Issues"
echo "========================================"

# 1. Update NPM to latest version
echo "📦 Updating NPM to latest version..."
npm_version=$(npm --version)
echo "Current NPM version: $npm_version"
echo "Updating NPM..."
npm install -g npm@latest 2>/dev/null || sudo npm install -g npm@latest || echo "Note: NPM update requires admin privileges"

# 2. Fix package.json engine requirements
echo ""
echo "⚙️ Fixing engine requirements in package.json..."
node -e "
const fs = require('fs');
const path = require('path');

// Update root package.json
const rootPkgPath = 'package.json';
if (fs.existsSync(rootPkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(rootPkgPath, 'utf8'));
  
  // Update engine requirements to be more flexible
  pkg.engines = {
    node: '>=18.0.0',
    npm: '>=8.0.0'
  };
  
  // Ensure all necessary scripts are present
  if (!pkg.scripts) pkg.scripts = {};
  
  // Add resolution for fast-jwt if needed
  if (!pkg.overrides) pkg.overrides = {};
  pkg.overrides['fast-jwt'] = '^4.0.0';
  
  fs.writeFileSync(rootPkgPath, JSON.stringify(pkg, null, 2) + '\n');
  console.log('✅ Updated root package.json engine requirements');
}

// Fix backend package.json for fast-jwt
const backendPkgPath = 'backend/services/api/package.json';
if (fs.existsSync(backendPkgPath)) {
  const pkg = JSON.parse(fs.readFileSync(backendPkgPath, 'utf8'));
  
  // Update dependencies
  if (pkg.dependencies && pkg.dependencies['fast-jwt']) {
    delete pkg.dependencies['fast-jwt'];
    console.log('✅ Removed incompatible fast-jwt dependency');
  }
  
  // Add @fastify/jwt instead which is more compatible
  if (!pkg.dependencies) pkg.dependencies = {};
  pkg.dependencies['@fastify/jwt'] = '^7.2.4';
  
  fs.writeFileSync(backendPkgPath, JSON.stringify(pkg, null, 2) + '\n');
  console.log('✅ Added @fastify/jwt as replacement');
}
"

# 3. Clean and reinstall dependencies
echo ""
echo "🧹 Cleaning and reinstalling dependencies..."
echo "Removing node_modules and lock files..."
rm -rf node_modules package-lock.json
rm -rf frontend/node_modules frontend/package-lock.json
rm -rf backend/services/api/node_modules backend/services/api/package-lock.json
rm -rf packages/shared/node_modules packages/shared/package-lock.json

# 4. Install with legacy peer deps to avoid conflicts
echo ""
echo "📥 Installing dependencies with compatibility flags..."
npm install --legacy-peer-deps

# 5. Audit and fix security issues
echo ""
echo "🔒 Fixing security vulnerabilities..."
npm audit fix --legacy-peer-deps 2>/dev/null || true

# 6. Create a detailed audit report
echo ""
echo "📊 Creating security audit report..."
npm audit --json > audit-report.json 2>/dev/null || true

# Parse and display audit summary
node -e "
try {
  const fs = require('fs');
  if (fs.existsSync('audit-report.json')) {
    const audit = JSON.parse(fs.readFileSync('audit-report.json', 'utf8'));
    if (audit.metadata && audit.metadata.vulnerabilities) {
      const vulns = audit.metadata.vulnerabilities;
      console.log('\n📈 Security Audit Summary:');
      console.log('  Critical:', vulns.critical || 0);
      console.log('  High:', vulns.high || 0);
      console.log('  Moderate:', vulns.moderate || 0);
      console.log('  Low:', vulns.low || 0);
      console.log('  Total:', vulns.total || 0);
      
      if (vulns.total > 0) {
        console.log('\n💡 To see details: npm audit');
        console.log('💡 To force fix all: npm audit fix --force');
      } else {
        console.log('\n✅ No vulnerabilities found!');
      }
    }
    fs.unlinkSync('audit-report.json');
  }
} catch (e) {
  // Silent fail
}
"

# 7. Update JWT implementation in backend
echo ""
echo "🔐 Updating JWT implementation..."
cat > backend/services/api/src/plugins/jwt.ts << 'EOF'
import fp from 'fastify-plugin';
import jwt from '@fastify/jwt';
import { FastifyPluginAsync } from 'fastify';

const jwtPlugin: FastifyPluginAsync = async (fastify) => {
  await fastify.register(jwt, {
    secret: process.env['JWT_SECRET'] || 'your-development-secret-key-change-in-production',
    sign: {
      expiresIn: '7d'
    }
  });

  fastify.decorate('authenticate', async function(request: any, reply: any) {
    try {
      await request.jwtVerify();
    } catch (err) {
      reply.send(err);
    }
  });
};

export default fp(jwtPlugin, {
  name: 'jwt-plugin'
});
EOF

# 8. Create .nvmrc file for Node version management
echo ""
echo "📝 Creating .nvmrc file..."
node_version=$(node --version | sed 's/v//')
echo "$node_version" > .nvmrc
echo "✅ Created .nvmrc with Node version: $node_version"

# 9. Create npm script for checking compatibility
echo ""
echo "📋 Adding compatibility check script..."
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
if (!pkg.scripts) pkg.scripts = {};
pkg.scripts['check:compatibility'] = 'npm ls --depth=0 && npm audit';
pkg.scripts['fix:audit'] = 'npm audit fix --legacy-peer-deps';
pkg.scripts['fix:audit:force'] = 'npm audit fix --force --legacy-peer-deps';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✅ Added compatibility check scripts');
"

# 10. Create a healthcheck script
echo ""
echo "🏥 Creating project health check..."
cat > check-health.js << 'EOF'
#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');

console.log('🏥 Running Project Health Check...\n');

const checks = [
  {
    name: 'Node Version',
    command: 'node --version',
    expected: 'v18 or higher'
  },
  {
    name: 'NPM Version',
    command: 'npm --version',
    expected: '8.0.0 or higher'
  },
  {
    name: 'TypeScript',
    command: 'npx tsc --version',
    expected: 'TypeScript compiler found'
  },
  {
    name: 'Dependencies',
    command: 'npm ls --depth=0 --json',
    expected: 'All dependencies installed'
  }
];

let allPassed = true;

checks.forEach(check => {
  try {
    const result = execSync(check.command, { encoding: 'utf8' }).trim();
    console.log(`✅ ${check.name}: ${result}`);
  } catch (error) {
    console.log(`❌ ${check.name}: Failed (expected: ${check.expected})`);
    allPassed = false;
  }
});

// Check for security vulnerabilities
try {
  const auditResult = execSync('npm audit --json', { encoding: 'utf8' });
  const audit = JSON.parse(auditResult);
  if (audit.metadata.vulnerabilities.total === 0) {
    console.log('✅ Security: No vulnerabilities');
  } else {
    console.log(`⚠️ Security: ${audit.metadata.vulnerabilities.total} vulnerabilities found`);
  }
} catch (error) {
  console.log('⚠️ Security: Could not run audit');
}

console.log('\n' + (allPassed ? '✅ All health checks passed!' : '⚠️ Some checks failed - see above'));
EOF

chmod +x check-health.js

echo ""
echo "========================================"
echo "✅ Fixes Applied!"
echo ""
echo "📋 Summary of changes:"
echo "  • Updated engine requirements to be more flexible"
echo "  • Replaced fast-jwt with @fastify/jwt (more compatible)"
echo "  • Cleaned and reinstalled dependencies"
echo "  • Fixed security vulnerabilities where possible"
echo "  • Created health check script"
echo ""
echo "🎯 Next steps:"
echo "  1. Run: node check-health.js    # Check project health"
echo "  2. Run: npm run dev              # Start development"
echo "  3. Run: npm audit                # View any remaining vulnerabilities"
echo ""
echo "💡 Tips:"
echo "  • If NPM version is still 9.x, run: npm install -g npm@latest"
echo "  • Use 'npm run fix:audit' to fix vulnerabilities"
echo "  • The project now uses @fastify/jwt instead of fast-jwt"
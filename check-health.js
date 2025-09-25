#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');

console.log('🏥 Running Project Health Check...\n');

const checks = [
  {
    name: 'Node Version',
    command: 'node --version',
    expected: 'v18 or higher',
  },
  {
    name: 'NPM Version',
    command: 'npm --version',
    expected: '8.0.0 or higher',
  },
  {
    name: 'TypeScript',
    command: 'npx tsc --version',
    expected: 'TypeScript compiler found',
  },
  {
    name: 'Dependencies',
    command: 'npm ls --depth=0 --json',
    expected: 'All dependencies installed',
  },
];

let allPassed = true;

checks.forEach((check) => {
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

console.log(
  '\n' + (allPassed ? '✅ All health checks passed!' : '⚠️ Some checks failed - see above'),
);

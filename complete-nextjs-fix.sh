#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     Complete Next.js 15 Fix & Setup Script    ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -d "frontend" ]; then
    echo -e "${RED}❌ Error: 'frontend' directory not found!${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory.${NC}"
    exit 1
fi

cd frontend

echo -e "${GREEN}✅ Step 1: Fixing next.config.js (removing deprecated swcMinify)${NC}"
cat > next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  compress: true,
  
  // TypeScript and ESLint
  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
  },

  // Image optimization
  images: {
    domains: ['localhost'],
    formats: ['image/avif', 'image/webp'],
  },

  // Disable telemetry
  telemetry: {
    disabled: true,
  },
}

module.exports = nextConfig
NEXTCONFIG

echo -e "${GREEN}✅ Step 2: Ensuring all required directories exist${NC}"
mkdir -p app/api
mkdir -p app/auth
mkdir -p src/components
mkdir -p src/lib
mkdir -p src/hooks
mkdir -p src/utils
mkdir -p src/types
mkdir -p src/services
mkdir -p public/images

echo -e "${GREEN}✅ Step 3: Creating missing type definition files${NC}"

# Create a types file for global types
cat > src/types/index.ts << 'TYPES'
// Global type definitions
export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'user' | 'guest'
}

export interface Project {
  id: string
  title: string
  description: string
  status: 'active' | 'completed' | 'archived'
  createdAt: Date
  updatedAt: Date
}

export interface ApiResponse<T = any> {
  success: boolean
  data?: T
  error?: string
  message?: string
}
TYPES

echo -e "${GREEN}✅ Step 4: Creating utility functions${NC}"

# Create a utils file
cat > src/utils/index.ts << 'UTILS'
// Utility functions
export const cn = (...classes: (string | undefined | boolean)[]) => {
  return classes.filter(Boolean).join(' ')
}

export const formatDate = (date: Date | string): string => {
  const d = new Date(date)
  return d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}

export const sleep = (ms: number): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms))
}
UTILS

echo -e "${GREEN}✅ Step 5: Creating example API route${NC}"

# Create an example API route
mkdir -p app/api/health
cat > app/api/health/route.ts << 'API'
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'frontend',
    version: '1.0.0',
  })
}
API

echo -e "${GREEN}✅ Step 6: Creating example component${NC}"

# Create a sample component
cat > src/components/Button.tsx << 'COMPONENT'
import React from 'react'

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
  children: React.ReactNode
}

export function Button({ 
  variant = 'primary', 
  size = 'md', 
  children, 
  className = '',
  ...props 
}: ButtonProps) {
  const baseStyles = 'inline-flex items-center justify-center font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2'
  
  const variants = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500',
    outline: 'border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-blue-500',
  }
  
  const sizes = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  }
  
  return (
    <button
      className={`${baseStyles} ${variants[variant]} ${sizes[size]} ${className}`}
      {...props}
    >
      {children}
    </button>
  )
}
COMPONENT

echo -e "${GREEN}✅ Step 7: Improving the homepage${NC}"

# Update the homepage with the new Button component
cat > app/page.tsx << 'HOMEPAGE'
'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Button } from '@/components/Button'

export default function HomePage() {
  const [count, setCount] = useState(0)
  const [loading, setLoading] = useState(false)

  const handleApiTest = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/health')
      const data = await response.json()
      alert(`API Status: ${data.status}\nTimestamp: ${data.timestamp}`)
    } catch (error) {
      alert('API Error: ' + error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-gray-900">
                🚀 Engineering App
              </h1>
            </div>
            <div className="flex items-center space-x-4">
              <Link
                href="/dashboard"
                className="text-gray-600 hover:text-gray-900 transition-colors"
              >
                Dashboard
              </Link>
            </div>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center">
          <h2 className="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
            Welcome to Next.js 15
          </h2>
          <p className="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
            Your modern engineering platform is ready with Next.js 15 and React 18!
          </p>
          
          <div className="mt-8 space-y-4">
            <div>
              <Button
                onClick={() => setCount(count + 1)}
                variant="primary"
                size="lg"
              >
                Count: {count}
              </Button>
            </div>

            <div>
              <Button
                onClick={handleApiTest}
                variant="secondary"
                size="md"
                disabled={loading}
              >
                {loading ? 'Testing...' : 'Test API Health'}
              </Button>
            </div>
          </div>

          <div className="mt-10 flex justify-center space-x-4">
            <Link href="/dashboard">
              <Button variant="primary" size="lg">
                Get Started →
              </Button>
            </Link>
            
            <a 
              href="https://nextjs.org/docs" 
              target="_blank" 
              rel="noopener noreferrer"
            >
              <Button variant="outline" size="lg">
                Learn More
              </Button>
            </a>
          </div>
        </div>

        <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-semibold mb-2">⚡ Fast Refresh</h3>
            <p className="text-gray-600">
              Experience instant feedback with Next.js Fast Refresh.
            </p>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-semibold mb-2">🎨 Tailwind CSS</h3>
            <p className="text-gray-600">
              Rapidly build modern websites with utility-first CSS.
            </p>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-semibold mb-2">📱 Responsive</h3>
            <p className="text-gray-600">
              Mobile-first responsive design out of the box.
            </p>
          </div>
        </div>
      </main>
    </div>
  )
}
HOMEPAGE

echo -e "${GREEN}✅ Step 8: Optimizing package.json scripts${NC}"

# Update package.json with better scripts
cat > package.json << 'PACKAGE'
{
  "name": "frontend",
  "version": "1.0.0",
  "private": true,
  "description": "Next.js 15 frontend with PWA support",
  "scripts": {
    "dev": "next dev -p 3000",
    "dev:turbo": "next dev --turbo -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint",
    "lint:fix": "next lint --fix",
    "type-check": "tsc --noEmit",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "clean": "rm -rf .next node_modules",
    "reinstall": "npm run clean && npm install",
    "analyze": "ANALYZE=true next build",
    "test": "echo 'No tests configured yet'"
  },
  "dependencies": {
    "next": "15.0.3",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "@tanstack/react-query": "^5.59.0",
    "axios": "^1.7.7",
    "clsx": "^2.1.1",
    "react-hook-form": "^7.53.0",
    "zod": "^3.23.8",
    "zustand": "^5.0.0",
    "tailwind-merge": "^2.5.2"
  },
  "devDependencies": {
    "@types/node": "^22.5.5",
    "@types/react": "^18.3.11",
    "@types/react-dom": "^18.3.1",
    "@typescript-eslint/eslint-plugin": "^8.8.1",
    "@typescript-eslint/parser": "^8.8.1",
    "@testing-library/react": "^16.0.1",
    "@testing-library/jest-dom": "^6.5.0",
    "@testing-library/user-event": "^14.5.2",
    "autoprefixer": "^10.4.20",
    "eslint": "^8.57.1",
    "eslint-config-next": "15.0.3",
    "postcss": "^8.4.47",
    "tailwindcss": "^3.4.13",
    "typescript": "^5.6.3",
    "prettier": "^3.3.3",
    "prettier-plugin-tailwindcss": "^0.6.5"
  },
  "engines": {
    "node": ">=20.0.0",
    "npm": ">=10.0.0"
  }
}
PACKAGE

echo -e "${GREEN}✅ Step 9: Creating .prettierrc for better formatting${NC}"

cat > .prettierrc << 'PRETTIER'
{
  "semi": false,
  "trailingComma": "es5",
  "singleQuote": true,
  "tabWidth": 2,
  "useTabs": false,
  "plugins": ["prettier-plugin-tailwindcss"]
}
PRETTIER

echo -e "${GREEN}✅ Step 10: Disabling Next.js telemetry${NC}"
npx next telemetry disable 2>/dev/null || true

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}       ✨ Setup Complete & Fixed! ✨          ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}📋 What was fixed/added:${NC}"
echo "  ✅ Removed deprecated swcMinify option"
echo "  ✅ Added API route example (/api/health)"
echo "  ✅ Created Button component"
echo "  ✅ Enhanced homepage with API test"
echo "  ✅ Added utility functions"
echo "  ✅ Created type definitions"
echo "  ✅ Improved package.json scripts"
echo "  ✅ Added Prettier configuration"
echo "  ✅ Disabled telemetry"
echo ""
echo -e "${YELLOW}🚀 Available commands:${NC}"
echo "  npm run dev        - Start development server"
echo "  npm run dev:turbo  - Start with Turbopack (faster)"
echo "  npm run build      - Build for production"
echo "  npm run lint:fix   - Fix linting issues"
echo "  npm run format     - Format all files"
echo "  npm run type-check - Check TypeScript types"
echo ""
echo -e "${GREEN}🎉 Your Next.js 15 app is ready to use!${NC}"
echo -e "${BLUE}   Visit: http://localhost:3000${NC}"
echo ""

# Return to root directory
cd ..

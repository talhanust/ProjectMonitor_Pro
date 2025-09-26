#!/bin/bash

echo "🔧 Complete Next.js 15 Setup Fix Script"
echo "========================================"

# Navigate to frontend directory
cd frontend

echo "📦 Step 1: Cleaning up old files..."
rm -rf node_modules package-lock.json .next
rm -f vite.config.ts index.html
rm -rf src/main.tsx src/App.tsx src/vite-env.d.ts

echo "📝 Step 2: Creating new package.json with React 18 (stable)..."
cat > package.json << 'PACKAGE'
{
  "name": "frontend",
  "version": "1.0.0",
  "private": true,
  "description": "Next.js 15 frontend with PWA support",
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage"
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
    "next-pwa": "^5.6.0",
    "tailwind-merge": "^2.5.2",
    "next-themes": "^0.3.0"
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
    "@vitest/ui": "^2.1.2",
    "autoprefixer": "^10.4.20",
    "eslint": "^8.57.1",
    "eslint-config-next": "15.0.3",
    "eslint-plugin-react": "^7.37.1",
    "eslint-plugin-react-hooks": "^5.0.0",
    "jsdom": "^25.0.1",
    "postcss": "^8.4.47",
    "tailwindcss": "^3.4.13",
    "typescript": "^5.6.3",
    "vitest": "^2.1.2"
  },
  "engines": {
    "node": ">=20.0.0",
    "npm": ">=10.0.0"
  }
}
PACKAGE

echo "📁 Step 3: Creating Next.js directory structure..."
mkdir -p app
mkdir -p app/dashboard
mkdir -p app/offline
mkdir -p src/components
mkdir -p src/lib
mkdir -p src/hooks
mkdir -p src/utils
mkdir -p src/types
mkdir -p public

echo "📝 Step 4: Creating Next.js configuration files..."

# Create next.config.js (simplified version without PWA first)
cat > next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
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
}

module.exports = nextConfig
NEXTCONFIG

# Create tsconfig.json
cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/hooks/*": ["./src/hooks/*"],
      "@/utils/*": ["./src/utils/*"],
      "@/types/*": ["./src/types/*"],
      "@/app/*": ["./app/*"]
    },
    "baseUrl": "."
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts",
    "app/**/*",
    "src/**/*"
  ],
  "exclude": ["node_modules"]
}
TSCONFIG

# Create next-env.d.ts
cat > next-env.d.ts << 'NEXTENV'
/// <reference types="next" />
/// <reference types="next/image-types/global" />
NEXTENV

# Create .eslintrc.json
cat > .eslintrc.json << 'ESLINTRC'
{
  "extends": ["next/core-web-vitals", "next/typescript"]
}
ESLINTRC

echo "📝 Step 5: Creating app files..."

# Create app/layout.tsx
cat > app/layout.tsx << 'LAYOUT'
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Engineering App',
  description: 'Modern engineering application with Next.js 15',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
LAYOUT

# Create app/page.tsx
cat > app/page.tsx << 'PAGE'
'use client'

import { useState } from 'react'
import Link from 'next/link'

export default function HomePage() {
  const [count, setCount] = useState(0)

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <nav className="bg-white shadow-sm border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-gray-900">
                Engineering App
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
            Your modern engineering platform is ready!
          </p>
          
          <div className="mt-8">
            <button
              onClick={() => setCount(count + 1)}
              className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 transition-colors"
            >
              Count: {count}
            </button>
          </div>

          <div className="mt-10">
            <Link
              href="/dashboard"
              className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 transition-all duration-200"
            >
              Get Started →
            </Link>
          </div>
        </div>
      </main>
    </div>
  )
}
PAGE

# Create app/globals.css
cat > app/globals.css << 'GLOBALS'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 0, 0, 0;
  --background-start-rgb: 214, 219, 220;
  --background-end-rgb: 255, 255, 255;
}

@media (prefers-color-scheme: dark) {
  :root {
    --foreground-rgb: 255, 255, 255;
    --background-start-rgb: 0, 0, 0;
    --background-end-rgb: 0, 0, 0;
  }
}

body {
  color: rgb(var(--foreground-rgb));
  background: linear-gradient(
      to bottom,
      transparent,
      rgb(var(--background-end-rgb))
    )
    rgb(var(--background-start-rgb));
}

@layer utilities {
  .text-balance {
    text-wrap: balance;
  }
}
GLOBALS

# Create app/dashboard/page.tsx
cat > app/dashboard/page.tsx << 'DASHBOARD'
export default function DashboardPage() {
  return (
    <div className="min-h-screen p-8 bg-gray-50">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">Dashboard</h1>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Projects</h2>
            <p className="text-3xl font-bold text-blue-600">12</p>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Tasks</h2>
            <p className="text-3xl font-bold text-green-600">48</p>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-lg font-semibold text-gray-700 mb-2">Team Members</h2>
            <p className="text-3xl font-bold text-purple-600">8</p>
          </div>
        </div>
        
        <div className="mt-8">
          <a href="/" className="text-blue-600 hover:text-blue-800 transition-colors">
            ← Back to Home
          </a>
        </div>
      </div>
    </div>
  )
}
DASHBOARD

# Update Tailwind config
cat > tailwind.config.ts << 'TAILWIND'
import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './src/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}

export default config
TAILWIND

# PostCSS config should already exist, but create if it doesn't
if [ ! -f postcss.config.js ]; then
  cat > postcss.config.js << 'POSTCSS'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
POSTCSS
fi

echo "📦 Step 6: Installing dependencies..."
npm install

echo "✨ Step 7: Creating additional helpful files..."

# Create .env.local
cat > .env.local << 'ENV'
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:8080
ENV

# Create public/robots.txt
cat > public/robots.txt << 'ROBOTS'
User-agent: *
Allow: /
ROBOTS

echo "🎉 Setup complete!"
echo ""
echo "✅ Next.js 15 has been successfully configured!"
echo ""
echo "📋 You can now:"
echo "1. Run 'npm run dev' to start the development server"
echo "2. Visit http://localhost:3000 to see your app"
echo "3. Edit app/page.tsx to modify the homepage"
echo ""
echo "🚀 Happy coding!"

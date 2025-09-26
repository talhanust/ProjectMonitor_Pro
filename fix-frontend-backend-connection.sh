#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Fix Frontend-Backend Connection Script     ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "frontend" ]; then
    echo -e "${RED}Error: Not in project root directory!${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Updating Frontend Configuration${NC}"

cd frontend

# Update next.config.js with proxy configuration
cat > next.config.js << 'NEXTCONFIG'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  compress: true,
  
  typescript: {
    ignoreBuildErrors: false,
  },
  eslint: {
    ignoreDuringBuilds: false,
  },

  images: {
    domains: ['localhost'],
    formats: ['image/avif', 'image/webp'],
  },

  // Proxy API calls to backend during development
  async rewrites() {
    return [
      {
        source: '/api/backend/:path*',
        destination: 'http://localhost:8080/:path*',
      },
    ]
  },
}

module.exports = nextConfig
NEXTCONFIG

echo -e "${GREEN}Step 2: Creating Enhanced Homepage with Backend Connection${NC}"

# Create an enhanced homepage that connects to backend
cat > app/page.tsx << 'HOMEPAGE'
'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'

export default function HomePage() {
  const [count, setCount] = useState(0)
  const [backendStatus, setBackendStatus] = useState<'checking' | 'online' | 'offline'>('checking')
  const [backendData, setBackendData] = useState<any>(null)

  useEffect(() => {
    checkBackendStatus()
    const interval = setInterval(checkBackendStatus, 30000) // Check every 30 seconds
    return () => clearInterval(interval)
  }, [])

  const checkBackendStatus = async () => {
    try {
      const response = await fetch('/api/backend/health')
      if (response.ok) {
        const data = await response.json()
        setBackendStatus('online')
        setBackendData(data)
      } else {
        setBackendStatus('offline')
      }
    } catch (error) {
      setBackendStatus('offline')
    }
  }

  const testFrontendAPI = async () => {
    try {
      const response = await fetch('/api/health')
      const data = await response.json()
      alert(`Frontend API: ${JSON.stringify(data, null, 2)}`)
    } catch (error) {
      alert('Frontend API Error: ' + error)
    }
  }

  const testBackendAPI = async () => {
    try {
      const response = await fetch('/api/backend/api/v1/status')
      const data = await response.json()
      alert(`Backend API: ${JSON.stringify(data, null, 2)}`)
    } catch (error) {
      alert('Backend API Error: ' + error)
    }
  }

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
            Welcome to Your Monorepo
          </h2>
          <p className="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
            Next.js 15 Frontend + Fastify Backend Working Together
          </p>
        </div>

        {/* Service Status */}
        <div className="mt-10 grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-semibold mb-2">Frontend Status</h3>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Next.js Server</span>
              <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                Online
              </span>
            </div>
            <div className="mt-2 text-sm text-gray-500">
              Port: 3000
            </div>
          </div>

          <div className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-lg font-semibold mb-2">Backend Status</h3>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Fastify API</span>
              <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                backendStatus === 'online' 
                  ? 'bg-green-100 text-green-800'
                  : backendStatus === 'offline'
                  ? 'bg-red-100 text-red-800'
                  : 'bg-yellow-100 text-yellow-800'
              }`}>
                {backendStatus === 'checking' ? 'Checking...' : 
                 backendStatus === 'online' ? 'Online' : 'Offline'}
              </span>
            </div>
            <div className="mt-2 text-sm text-gray-500">
              Port: 8080
              {backendData && (
                <div className="mt-1 text-xs">
                  Service: {backendData.service}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Test Buttons */}
        <div className="mt-10 flex flex-col items-center space-y-4">
          <div className="flex space-x-4">
            <button
              onClick={() => setCount(count + 1)}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors"
            >
              Count: {count}
            </button>

            <button
              onClick={testFrontendAPI}
              className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition-colors"
            >
              Test Frontend API
            </button>

            <button
              onClick={testBackendAPI}
              className="px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 transition-colors"
            >
              Test Backend API
            </button>

            <button
              onClick={checkBackendStatus}
              className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition-colors"
            >
              Refresh Status
            </button>
          </div>

          <Link
            href="/dashboard"
            className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700"
          >
            Get Started →
          </Link>
        </div>

        {/* API Endpoints Info */}
        <div className="mt-16 bg-white rounded-lg shadow p-6 max-w-4xl mx-auto">
          <h3 className="text-lg font-semibold mb-4">Available API Endpoints</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <h4 className="font-medium text-gray-700 mb-2">Frontend Routes</h4>
              <ul className="space-y-1 text-gray-600">
                <li><code className="bg-gray-100 px-1 rounded">/</code> - Homepage</li>
                <li><code className="bg-gray-100 px-1 rounded">/dashboard</code> - Dashboard</li>
                <li><code className="bg-gray-100 px-1 rounded">/api/health</code> - Frontend health check</li>
              </ul>
            </div>
            <div>
              <h4 className="font-medium text-gray-700 mb-2">Backend Routes (via proxy)</h4>
              <ul className="space-y-1 text-gray-600">
                <li><code className="bg-gray-100 px-1 rounded">/api/backend/health</code> - Backend health</li>
                <li><code className="bg-gray-100 px-1 rounded">/api/backend/api/v1/status</code> - API status</li>
              </ul>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}
HOMEPAGE

echo -e "${GREEN}Step 3: Creating Start Script${NC}"

cd ..

# Create a convenient start script
cat > start-dev.sh << 'STARTSCRIPT'
#!/bin/bash

echo "Starting Development Servers..."
echo "================================"

# Function to kill processes on ports
cleanup() {
    echo ""
    echo "Stopping servers..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null
    lsof -ti:8080 | xargs kill -9 2>/dev/null
    exit 0
}

# Set up cleanup on exit
trap cleanup EXIT INT TERM

# Start backend
echo "Starting Backend API on port 8080..."
(cd backend/services/api && npm run dev) &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Start frontend
echo "Starting Frontend on port 3000..."
(cd frontend && npm run dev) &
FRONTEND_PID=$!

echo ""
echo "================================"
echo "Services are starting..."
echo "Frontend: http://localhost:3000"
echo "Backend:  http://localhost:8080"
echo "================================"
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID
STARTSCRIPT

chmod +x start-dev.sh

echo -e "${GREEN}Step 4: Creating Test Script${NC}"

# Create a test script to verify everything works
cat > test-services.sh << 'TESTSCRIPT'
#!/bin/bash

echo "Testing Services..."
echo "=================="

# Test Frontend
echo -n "Frontend Health: "
curl -s http://localhost:3000/api/health | jq '.' 2>/dev/null || echo "Not responding"

# Test Backend directly
echo -n "Backend Health (direct): "
curl -s http://localhost:8080/health | jq '.' 2>/dev/null || echo "Not responding"

# Test Backend through proxy
echo -n "Backend Health (via proxy): "
curl -s http://localhost:3000/api/backend/health | jq '.' 2>/dev/null || echo "Not responding"

# Test Backend API status through proxy
echo -n "Backend Status (via proxy): "
curl -s http://localhost:3000/api/backend/api/v1/status | jq '.' 2>/dev/null || echo "Not responding"

echo ""
echo "=================="
TESTSCRIPT

chmod +x test-services.sh

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}           Setup Complete!                     ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}What was fixed:${NC}"
echo "  - Next.js proxy configuration for backend API"
echo "  - Enhanced homepage with service status monitoring"
echo "  - Start script for running both services"
echo "  - Test script for verifying connections"
echo ""
echo -e "${YELLOW}To start your application:${NC}"
echo ""
echo "  Option 1 - Use the start script:"
echo "    ${BLUE}./start-dev.sh${NC}"
echo ""
echo "  Option 2 - Run manually:"
echo "    Terminal 1: ${BLUE}cd backend/services/api && npm run dev${NC}"
echo "    Terminal 2: ${BLUE}cd frontend && npm run dev${NC}"
echo ""
echo -e "${YELLOW}To test the services:${NC}"
echo "    ${BLUE}./test-services.sh${NC}"
echo ""
echo -e "${GREEN}Your monorepo is ready with frontend-backend communication!${NC}"

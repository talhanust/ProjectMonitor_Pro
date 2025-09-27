#!/bin/bash
# update-frontend-proxy.sh
# This script updates frontend/next.config.js to proxy API requests to the new API Gateway

CONFIG_FILE="frontend/next.config.js"

cat > $CONFIG_FILE << 'EOF'
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

  // Proxy API calls to backend services
  async rewrites() {
    return [
      {
        source: '/api/gateway/:path*',
        destination: 'http://localhost:8080/:path*',
      },
      {
        source: '/api/backend/:path*',
        destination: 'http://localhost:8080/:path*',
      },
    ]
  },
}

module.exports = nextConfig
EOF

echo "✅ Frontend proxy updated successfully in $CONFIG_FILE"

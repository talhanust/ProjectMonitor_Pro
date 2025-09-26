#!/bin/bash

echo "🚀 Setting up Next.js 15 with React 19 and PWA support..."

# Navigate to frontend directory
cd frontend

# Backup existing files if they exist
if [ -f "package.json" ]; then
  mv package.json package.json.bak
  echo "📦 Backed up existing package.json"
fi

# Create required directories
echo "📁 Creating directory structure..."
mkdir -p app
mkdir -p src/components
mkdir -p src/lib
mkdir -p src/hooks
mkdir -p src/utils
mkdir -p src/types
mkdir -p src/styles
mkdir -p public

# Create next-env.d.ts
cat > next-env.d.ts << 'EOF'
/// <reference types="next" />
/// <reference types="next/image-types/global" />

// NOTE: This file should not be edited
// see https://nextjs.org/docs/basic-features/typescript for more information.
EOF

# Create .eslintrc.json for Next.js
cat > .eslintrc.json << 'EOF'
{
  "extends": ["next/core-web-vitals", "next/typescript"]
}
EOF

# Create next.config.mjs if next.config.js doesn't work with ES modules
cat > next.config.mjs << 'EOF'
import withPWAInit from 'next-pwa';

const withPWA = withPWAInit({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development',
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  experimental: {
    ppr: true,
  },
};

export default withPWA(nextConfig);
EOF

# Create a simple dashboard page placeholder
mkdir -p app/dashboard
cat > app/dashboard/page.tsx << 'EOF'
export default function DashboardPage() {
  return (
    <div className="min-h-screen p-8">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      <p className="mt-4 text-gray-600">Welcome to your dashboard!</p>
    </div>
  );
}
EOF

# Create placeholder icons
echo "🎨 Creating placeholder icons..."
cat > public/icon.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="#3b82f6">
  <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
</svg>
EOF

# Create .env.local file
cat > .env.local << 'EOF'
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:8080
EOF

# Install dependencies
echo "📦 Installing Next.js 15 and dependencies..."
npm install next@latest react@rc react-dom@rc

echo "📦 Installing additional dependencies..."
npm install @tanstack/react-query axios clsx react-hook-form zod zustand tailwind-merge next-themes

echo "📦 Installing dev dependencies..."
npm install -D @types/react @types/react-dom @types/node typescript tailwindcss postcss autoprefixer eslint eslint-config-next

echo "📦 Installing PWA support..."
npm install next-pwa@latest

# Initialize Tailwind if needed
if [ ! -f "tailwind.config.ts" ]; then
  echo "🎨 Initializing Tailwind CSS..."
  npx tailwindcss init -p --ts
fi

echo "✅ Next.js 15 setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Copy the artifact files to their respective locations"
echo "2. Run 'npm run dev' to start the development server"
echo "3. Visit http://localhost:3000 to see your app"
echo "4. The app is PWA-ready and will work offline!"
echo ""
echo "🎯 Features enabled:"
echo "- Next.js 15 with App Router"
echo "- React 19 RC"
echo "- TypeScript"
echo "- Tailwind CSS"
echo "- PWA with offline support"
echo "- Service Worker caching"
echo "- App installation prompt"
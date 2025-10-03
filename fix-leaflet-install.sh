#!/bin/bash

cd frontend

echo "Installing Leaflet with compatible versions..."

# Install compatible version of react-leaflet for React 18
npm install leaflet@^1.9.4 react-leaflet@^4.2.1 @types/leaflet --legacy-peer-deps

echo "✅ Leaflet dependencies installed successfully!"

# Verify installation
if [ -d "node_modules/leaflet" ] && [ -d "node_modules/react-leaflet" ]; then
  echo "✅ Leaflet packages are installed"
else
  echo "⚠️ Installation may have issues, trying alternative approach..."
  npm install leaflet react-leaflet@4.2.1 @types/leaflet --force
fi

echo ""
echo "Setup complete! The GPS picker will work with:"
echo "  • Leaflet (no API key needed)"
echo "  • OpenStreetMap tiles (free)"
echo "  • Click-to-select coordinates"
echo ""
echo "Start your services:"
echo "1. Backend: cd backend/services/project-service && npm run dev"
echo "2. Frontend: cd frontend && npm run dev"

cd ..

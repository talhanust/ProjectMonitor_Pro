#!/bin/bash
set -e

echo "🚀 Running setup_project.sh..."

# ----------------------------
# Step 0: Ensure Husky globally (dev) before npm install
# ----------------------------
echo "🔧 Ensuring Husky is installed..."
cd backend/services/api
if ! npx husky --version >/dev/null 2>&1; then
    echo "⚠️ Husky not found, installing..."
    npm install husky --save-dev
    npx husky install || true
else
    echo "✅ Husky already installed."
fi
cd ../../..

# ----------------------------
# Step 1: Run the main setup script
# ----------------------------
chmod +x ./setup_project.sh
./setup_project.sh

echo "🎉 Dev environment setup complete! You can now run 'npm run dev'."

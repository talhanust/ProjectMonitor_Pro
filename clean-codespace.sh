# Cleanup script for Codespaces
echo "🧹 Cleaning up Codespace..."

# Remove node_modules, build artifacts, caches
rm -rf node_modules
rm -rf */*/node_modules
rm -rf .next dist build
rm -rf */*/.next */*/dist */*/build

# Clean npm + yarn cache
npm cache clean --force
yarn cache clean --all 2>/dev/null || true

# Clean Docker (sometimes Codespaces uses it)
docker system prune -af --volumes 2>/dev/null || true

echo "✅ Cleanup complete. Restarting Codespace is recommended."

#!/bin/bash

case "$1" in
"clean")
echo "Cleaning all node_modules and build artifacts..."
find . -name "node_modules" -type d -prune -exec rm -rf {} + 2>/dev/null
find . -name "dist" -type d -prune -exec rm -rf {} + 2>/dev/null
find . -name ".next" -type d -prune -exec rm -rf {} + 2>/dev/null
echo "Clean complete!"
;;
"install")
echo "Installing all dependencies..."
npm install
echo "Install complete!"
;;
"typecheck")
echo "Running type check..."
npm run typecheck
;;
"test")
echo "Running all tests..."
npm test
;;
*)
echo "Usage: $0 {clean|install|typecheck|test}"
exit 1
;;
esac

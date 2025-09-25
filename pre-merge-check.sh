#!/bin/bash
set -e

echo "🔹 Starting pre-merge checks..."

# 1️⃣ Run ESLint with auto-fix
echo "🔍 Running ESLint with auto-fix..."
npx eslint . --ext .ts,.tsx,.js,.jsx --fix
echo "✅ ESLint auto-fix applied (if any issues were fixable)"

# 2️⃣ Check Prettier formatting
echo "🔍 Checking and fixing code formatting with Prettier..."
npx prettier --write "**/*.{ts,tsx,js,jsx,json,md}"
npx prettier --check "**/*.{ts,tsx,js,jsx,json,md}"
echo "✅ Prettier formatting is correct"

# 3️⃣ Compile TypeScript in each workspace
echo "🔍 Compiling TypeScript in each workspace..."

workspaces=("frontend" "backend/services/api" "packages/shared")
for ws in "${workspaces[@]}"; do
  if [ -f "$ws/tsconfig.json" ]; then
    echo "🔹 Compiling $ws..."
    if ! npx tsc -p "$ws/tsconfig.json" --noEmit; then
      echo "❌ TypeScript compilation failed in $ws. Fix type errors before merging."
      exit 1
    fi
  else
    echo "⚠️  No tsconfig.json found in $ws, skipping..."
  fi
done

echo "✅ TypeScript compilation passed in all workspaces"

# 4️⃣ Done
echo "🎉 All pre-merge checks passed!"

#!/bin/bash
set -e

echo "🔧 Starting ESLint & Prettier fixes..."

# 1. Remove bad tailwind.config.js if it exists
if [ -f "frontend/tailwind.config.js" ]; then
  echo "🗑️ Removing frontend/tailwind.config.js (duplicate, invalid TypeScript syntax)..."
  rm frontend/tailwind.config.js
  git add frontend/tailwind.config.js
else
  echo "✅ No duplicate tailwind.config.js found."
fi

# 2. Ensure eslint-env node is at top of next.config.js & postcss.config.js
FILES=(
  "frontend/next.config.js"
  "frontend/postcss.config.js"
)

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    if ! grep -q "eslint-env node" "$FILE"; then
      echo "⚡ Patching $FILE with /* eslint-env node */ ..."
      sed -i '1i /* eslint-env node */' "$FILE"
      git add "$FILE"
    else
      echo "✅ $FILE already patched."
    fi
  else
    echo "⚠️ $FILE not found, skipping..."
  fi
done

# 3. Stage all changes (including backend fix)
git add .

# 4. Commit with message
echo "💾 Committing changes..."
git commit -m "fix: resolve ESLint & Prettier issues, add backend root route"

echo "🎉 Fix complete! Now you can push with:"
echo "   git push origin fix/backend-root-route"

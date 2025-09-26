#!/bin/bash

set -e

FILES=(
  "frontend/next.config.js"
  "frontend/postcss.config.js"
)

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    # Check if the directive is already there
    if ! grep -q "eslint-env node" "$FILE"; then
      echo "Patching $FILE..."
      sed -i '1i /* eslint-env node */' "$FILE"
    else
      echo "$FILE already patched."
    fi
  else
    echo "⚠️ $FILE not found, skipping..."
  fi
done

echo "✅ ESLint node env directive added!"

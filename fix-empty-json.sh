#!/bin/bash

# File: fix-empty-json.sh
# Description: Script to patch the backend's src/index.ts file to handle empty JSON bodies in Fastify.
# Assumptions: 
# - Your backend workspace is at 'backend/services/api/src/index.ts' (adjusted based on your 'find' output).
# - The Fastify app is initialized with 'const app = fastify({ logger: true });' (adjust the sed pattern if your init line differs).
# Usage: Save this as fix-empty-json.sh, chmod +x fix-empty-json.sh, then run ./fix-empty-json.sh from the project root.
# Warning: This uses sed to edit in-place. Always review changes or use git for versioning.

# Set the path to your index.ts file (adjusted)
FILE_PATH="backend/services/api/src/index.ts"  # Adjusted based on your find output

# Check if the file exists
if [ ! -f "$FILE_PATH" ]; then
  echo "Error: File $FILE_PATH not found. Please adjust FILE_PATH in this script to match your backend's src/index.ts location."
  echo "Tip: Run 'find . -name index.ts' from the project root to locate it, then update FILE_PATH."
  exit 1
fi

# Backup the original file
cp -p "$FILE_PATH" "$FILE_PATH.bak"
echo "Backup created: $FILE_PATH.bak"

# Insert the custom parser code after the app initialization line
sed -i '/const app = fastify({ logger: true });/a \
\
app.addContentTypeParser(\x27application/json\x27, { parseAs: \x27string\x27 }, (req, body, done) => {\
  try {\
    const json = body === \x27\x27 ? {} : JSON.parse(body);\
    done(null, json);\
  } catch (err) {\
    err.statusCode = 400;\
    done(err, undefined);\
  }\
});' "$FILE_PATH"

echo "Patch applied to $FILE_PATH. Review the changes, then restart your backend dev server to test."
echo "If the insertion point doesn't match, edit manually or adjust the sed pattern."
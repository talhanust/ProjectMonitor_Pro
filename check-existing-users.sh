#!/bin/bash

# Check Existing Users in Database
# Shows registered users and their emails

set -e

echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           Check Existing Users in Database                          ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get database URL from env
DB_URL=$(grep DATABASE_URL /workspaces/ProjectMonitor_Pro/backend/services/api-gateway/.env 2>/dev/null | cut -d'=' -f2)

if [ -z "$DB_URL" ]; then
    echo -e "${YELLOW}⚠${NC} Database URL not found in .env"
    echo ""
    echo "Checking Supabase users instead..."
    echo ""
    echo "To check Supabase users:"
    echo "  1. Go to: https://supabase.com/dashboard"
    echo "  2. Select your project: zblwtlffcczydccrheiq"
    echo "  3. Go to Authentication → Users"
    echo ""
    exit 0
fi

echo -e "${BLUE}[1/2]${NC} Connecting to PostgreSQL database..."

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} psql not found. Installing postgresql-client..."
    sudo apt-get update -qq && sudo apt-get install -y postgresql-client -qq
fi

echo -e "${GREEN}✓${NC} Connected to database"
echo ""

echo -e "${BLUE}[2/2]${NC} Fetching users..."
echo ""

# Query users table
psql "$DB_URL" -c "
SELECT 
    id,
    email,
    name,
    role,
    created_at
FROM users
ORDER BY created_at DESC
LIMIT 10;
" 2>/dev/null || {
    echo -e "${YELLOW}⚠${NC} Could not query users table directly"
    echo ""
    echo "Alternative: Check Supabase Dashboard"
    echo "  1. Go to: https://supabase.com/dashboard"
    echo "  2. Select your project"
    echo "  3. Go to Authentication → Users"
    echo ""
    echo "Or try creating a new account at /login"
}

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║           User Check Complete                                       ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""
echo "To sign in:"
echo "  1. Go to: ${GREEN}http://localhost:3000/login${NC}"
echo "  2. Enter your email and password"
echo "  3. Click 'Sign in'"
echo ""
echo "Or create new account:"
echo "  1. Click 'create a new account' link"
echo "  2. Fill in email, password, and name"
echo "  3. Submit registration"
echo ""
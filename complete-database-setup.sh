#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Completing Database Setup                  ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Navigate to shared directory
cd backend/services/shared

# Create .env file in the shared directory if it doesn't exist
echo -e "${GREEN}Setting up environment...${NC}"
cat > .env << 'ENV'
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/engineering_app
ENV

# Generate Prisma Client
echo -e "${GREEN}Generating Prisma Client...${NC}"
npx prisma generate

# Reset database before migrations (for dev only!)
echo -e "${GREEN}Resetting database...${NC}"
npx prisma migrate reset --force --skip-seed

# Run migrations
echo -e "${GREEN}Running migrations...${NC}"
npx prisma migrate dev --name initial

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Migration successful!${NC}"
    
    # Seed the database
    echo -e "${GREEN}Seeding database with test data...${NC}"
    npm run prisma:seed
    
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${GREEN}    Database Setup Complete! 🎉               ${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
    echo -e "${GREEN}Database is ready with:${NC}"
    echo "  ✓ All tables created"
    echo "  ✓ Migrations applied"
    echo "  ✓ Test data seeded"
    echo ""
    echo -e "${YELLOW}Test users created:${NC}"
    echo "  • admin@example.com / Admin123!"
    echo "  • john.doe@example.com / User123!"
    echo "  • jane.smith@example.com / User123!"
    echo ""
    echo -e "${YELLOW}Sample data includes:${NC}"
    echo "  • 2 Projects (Website Redesign, Mobile App)"
    echo "  • 3 Tasks with various statuses"
    echo "  • Comments, milestones, and activities"
    echo ""
    echo -e "${YELLOW}To explore your data:${NC}"
    echo "  1. Prisma Studio (GUI):"
    echo "     ${BLUE}npx prisma studio${NC}"
    echo ""
    echo "  2. Adminer (Web UI):"
    echo "     ${BLUE}http://localhost:8090${NC}"
    echo "     Server: postgres"
    echo "     Username: postgres"
    echo "     Password: postgres"
    echo "     Database: engineering_app"
    echo ""
    echo "  3. Direct PostgreSQL:"
    echo "     ${BLUE}docker exec -it engineering_postgres psql -U postgres -d engineering_app${NC}"
else
    echo -e "${YELLOW}Troubleshooting migration failure:${NC}"
    echo "  1. Check connection:"
    echo "     ${BLUE}docker exec -it engineering_postgres psql -U postgres -l${NC}"
    echo "  2. View detailed logs:"
    echo "     ${BLUE}docker logs engineering_postgres --tail 50${NC}"
fi

cd ../../..

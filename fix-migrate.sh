# Update the backend package.json with dotenv-cli
cd backend/services/api
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.scripts.migrate = 'dotenv -e ../../../.env -- prisma migrate dev';
pkg.scripts['migrate:deploy'] = 'dotenv -e ../../../.env -- prisma migrate deploy';
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✅ Updated migration scripts');
"
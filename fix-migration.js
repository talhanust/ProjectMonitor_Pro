// fix-migration.js
import { execSync } from 'child_process';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load only Prisma-specific .env and ignore root .env
const prismaEnvPath = path.join(__dirname, 'backend/services/api/prisma/.env');
dotenv.config({ path: prismaEnvPath, override: true });

console.log(`[dotenv] Loaded env from ${prismaEnvPath}`);
console.log('🔧 Starting migration fix...');
console.log('🌍 Using DATABASE_URL:', process.env.DATABASE_URL);
console.log('🔑 NODE_ENV:', process.env.NODE_ENV);

// Build env object with Prisma override
const prismaEnv = {
  ...process.env,
  PRISMA_IGNORE_ENV_FILE: '1', // ✅ ignore root .env
};

// Ensure Prisma client is generated before import
try {
  console.log('⚙️ Running prisma generate...');
  execSync(`npx prisma generate --schema ./backend/services/api/prisma/schema.prisma`, {
    stdio: 'inherit',
    env: prismaEnv,
  });
  console.log('✅ Prisma client generated.');
} catch (err) {
  console.error('❌ Failed to generate Prisma client:', err.message);
  process.exit(1);
}

// Import Prisma client after generation
import pkg from '@prisma/client';
const { PrismaClient } = pkg;
const prisma = new PrismaClient();

async function main() {
  // Ensure default user exists
  console.log('👤 Ensuring default user exists...');
  const defaultUser = await prisma.user.upsert({
    where: { email: 'default@example.com' },
    update: {},
    create: {
      email: 'default@example.com',
      password: 'defaultpassword', // ⚠️ hash in production
      name: 'Default User',
    },
  });
  console.log(`✅ Default user ready: ${defaultUser.email} (id=${defaultUser.id})`);

  // Detect correct column name
  console.log('🔍 Checking Project table columns...');
  const columnCheck = await prisma.$queryRawUnsafe(`
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'Project';
  `);

  const cols = columnCheck.map((r) => r.column_name);
  const linkColumn = cols.includes('ownerId') ? 'ownerId' : 'userId';

  console.log(`📌 Using column: ${linkColumn}`);

  // Attach orphaned projects
  console.log('🔗 Attaching orphaned projects to default user...');
  await prisma.$executeRawUnsafe(`
    UPDATE "Project"
    SET "${linkColumn}" = ${defaultUser.id}
    WHERE "${linkColumn}" IS NULL;
  `);
  console.log('✅ Orphaned projects updated.');

  // Apply migrations
  console.log('✍️ Running prisma migrate dev...');
  try {
    execSync(`npx prisma migrate dev --schema ./backend/services/api/prisma/schema.prisma`, {
      stdio: 'inherit',
      env: prismaEnv,
    });
    console.log('✅ Migration completed.');
  } catch (err) {
    console.error('❌ Migration fix failed:', err.message);
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (err) => {
    console.error('❌ Migration fix failed:', err);
    await prisma.$disconnect();
    process.exit(1);
  });

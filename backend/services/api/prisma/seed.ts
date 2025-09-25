import { PrismaClient } from '@prisma/client';
import { config } from '../src/config/env'; // ✅ central env loader

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting seed with DB:', config.DATABASE_URL);

  // Seed Users
  const alice = await prisma.user.upsert({
    where: { email: 'alice@example.com' },
    update: {},
    create: {
      email: 'alice@example.com',
      name: 'Alice',
    },
  });

  const bob = await prisma.user.upsert({
    where: { email: 'bob@example.com' },
    update: {},
    create: {
      email: 'bob@example.com',
      name: 'Bob',
    },
  });

  // Seed Projects (assign to users)
  await prisma.project.createMany({
    data: [
      {
        name: 'Monitoring App',
        description: 'First project for testing',
        status: 'active',
        ownerId: alice.id, // 👈 assigned to Alice
      },
      {
        name: 'Backend API',
        description: 'Service for handling requests',
        status: 'pending',
        ownerId: bob.id, // 👈 assigned to Bob
      },
    ],
    skipDuplicates: true,
  });

  console.log('✅ Seed complete:', { alice, bob });
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

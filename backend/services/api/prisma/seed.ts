import { PrismaClient, Status } from '@prisma/client';
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
      password: 'password123', // 👈 required by schema
    },
  });

  const bob = await prisma.user.upsert({
    where: { email: 'bob@example.com' },
    update: {},
    create: {
      email: 'bob@example.com',
      name: 'Bob',
      password: 'password123',
    },
  });

  // Seed Projects (assign to users with unique codes)
  await prisma.project.createMany({
    data: [
      {
        code: 'PRJ001', // 👈 required unique code
        title: 'Monitoring App',
        description: 'First project for testing',
        status: Status.ACTIVE,
        userId: alice.id, // 👈 assigned to Alice
      },
      {
        code: 'PRJ002',
        title: 'Backend API',
        description: 'Service for handling requests',
        status: Status.ACTIVE,
        userId: bob.id, // 👈 assigned to Bob
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

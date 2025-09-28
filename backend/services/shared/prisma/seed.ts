import { PrismaClient } from '@prisma/client'
import * as bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Starting database seed...')

  // Create admin user
  const adminPassword = await bcrypt.hash('Admin123!', 10)
  const admin = await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      password: adminPassword,
      name: 'Admin User',
      role: 'ADMIN',
      emailVerified: new Date(),
    },
  })
  console.log('✓ Admin user created')

  // Create regular users
  const userPassword = await bcrypt.hash('User123!', 10)
  const users = await Promise.all([
    prisma.user.upsert({
      where: { email: 'john.doe@example.com' },
      update: {},
      create: {
        email: 'john.doe@example.com',
        password: userPassword,
        name: 'John Doe',
        role: 'USER',
        emailVerified: new Date(),
      },
    }),
    prisma.user.upsert({
      where: { email: 'jane.smith@example.com' },
      update: {},
      create: {
        email: 'jane.smith@example.com',
        password: userPassword,
        name: 'Jane Smith',
        role: 'MANAGER',
        emailVerified: new Date(),
      },
    }),
  ])
  console.log('✓ Regular users created')

  // Create sample projects
  const project1 = await prisma.project.create({
    data: {
      name: 'Website Redesign',
      description: 'Complete redesign of company website',
      code: 'WEB-2024',
      status: 'IN_PROGRESS',
      ownerId: admin.id,
      startDate: new Date('2024-01-01'),
      endDate: new Date('2024-06-30'),
      members: {
        create: [
          { userId: users[0].id, role: 'lead' },
          { userId: users[1].id, role: 'member' },
        ],
      },
    },
  })

  const project2 = await prisma.project.create({
    data: {
      name: 'Mobile App Development',
      description: 'Native mobile app for iOS and Android',
      code: 'MOB-2024',
      status: 'PLANNING',
      ownerId: users[1].id,
      members: {
        create: [
          { userId: users[0].id, role: 'member' },
          { userId: admin.id, role: 'viewer' },
        ],
      },
    },
  })
  console.log('✓ Sample projects created')

  // Create milestones
  const milestone1 = await prisma.milestone.create({
    data: {
      name: 'Phase 1 - Design',
      description: 'Complete design mockups and prototypes',
      dueDate: new Date('2024-02-28'),
      projectId: project1.id,
    },
  })
  console.log('✓ Milestones created')

  // Create sample tasks
  const tasks = await Promise.all([
    prisma.task.create({
      data: {
        title: 'Create wireframes',
        description: 'Design initial wireframes for all pages',
        code: 'TASK-001',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        projectId: project1.id,
        assigneeId: users[0].id,
        creatorId: admin.id,
        milestoneId: milestone1.id,
        estimatedHours: 16,
      },
    }),
    prisma.task.create({
      data: {
        title: 'Setup development environment',
        description: 'Configure development tools and dependencies',
        code: 'TASK-002',
        status: 'DONE',
        priority: 'MEDIUM',
        projectId: project1.id,
        assigneeId: users[1].id,
        creatorId: admin.id,
        estimatedHours: 8,
        actualHours: 6,
        completedAt: new Date(),
      },
    }),
    prisma.task.create({
      data: {
        title: 'Market research',
        description: 'Research competitor apps and features',
        code: 'TASK-003',
        status: 'TODO',
        priority: 'HIGH',
        projectId: project2.id,
        assigneeId: users[0].id,
        creatorId: users[1].id,
        estimatedHours: 24,
      },
    }),
  ])
  console.log('✓ Sample tasks created')

  // Create comments
  await prisma.comment.create({
    data: {
      content: 'Looking good so far! Keep up the great work.',
      taskId: tasks[0].id,
      authorId: admin.id,
    },
  })
  console.log('✓ Sample comments created')

  // Create tags
  const tags = await Promise.all([
    prisma.tag.upsert({
      where: { name: 'urgent' },
      update: {},
      create: { name: 'urgent', color: '#FF0000' },
    }),
    prisma.tag.upsert({
      where: { name: 'frontend' },
      update: {},
      create: { name: 'frontend', color: '#00FF00' },
    }),
    prisma.tag.upsert({
      where: { name: 'backend' },
      update: {},
      create: { name: 'backend', color: '#0000FF' },
    }),
  ])
  console.log('✓ Tags created')

  // Create activities
  await prisma.activity.create({
    data: {
      action: 'created',
      entityType: 'project',
      entityId: project1.id,
      userId: admin.id,
      projectId: project1.id,
      metadata: { projectName: project1.name },
    },
  })
  console.log('✓ Sample activities created')

  // Create notifications
  await prisma.notification.create({
    data: {
      type: 'task_assigned',
      title: 'New Task Assigned',
      message: 'You have been assigned to "Create wireframes"',
      userId: users[0].id,
      data: { taskId: tasks[0].id },
    },
  })
  console.log('✓ Sample notifications created')

  console.log('✅ Database seed completed!')
}

main()
  .catch((e) => {
    console.error('❌ Error during seed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })

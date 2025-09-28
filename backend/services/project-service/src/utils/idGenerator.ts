import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function generateProjectId(): Promise<string> {
  const year = new Date().getFullYear();
  
  // Get or create counter for current year
  const counter = await prisma.projectCounter.upsert({
    where: { year },
    update: { 
      counter: { increment: 1 } 
    },
    create: { 
      year,
      counter: 1 
    }
  });
  
  // Format: DIR-YYYY-XXXX (e.g., DIR-2025-0001)
  const projectId = `DIR-${year}-${String(counter.counter).padStart(4, '0')}`;
  
  return projectId;
}

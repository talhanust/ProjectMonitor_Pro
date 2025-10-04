import { projectRepository } from '../repositories/projectRepository';
import { generateProjectId } from '../utils/idGenerator';
import { CreateProjectDTO, UpdateProjectDTO } from '../models/project.model';

export class ProjectService {
  async createProject(data: CreateProjectDTO, userId?: string) {
    // Generate unique project ID
    const projectId = await generateProjectId();

    // Create project
    const project = await projectRepository.create({
      ...data,
      projectId,
      createdBy: userId,
    });

    return project;
  }

  async getProject(id: string) {
    const project = await projectRepository.findById(id);
    if (!project) {
      throw new Error('Project not found');
    }
    return project;
  }

  async getProjectByProjectId(projectId: string) {
    const project = await projectRepository.findByProjectId(projectId);
    if (!project) {
      throw new Error('Project not found');
    }
    return project;
  }

  async updateProject(id: string, data: UpdateProjectDTO, userId?: string) {
    // Check if project exists
    await this.getProject(id);

    // Update project
    const project = await projectRepository.update(id, {
      ...data,
      updatedBy: userId,
    });

    return project;
  }

  async deleteProject(id: string) {
    // Check if project exists
    await this.getProject(id);

    // Delete project
    await projectRepository.delete(id);

    return { message: 'Project deleted successfully' };
  }

  async listProjects(query: any) {
    return await projectRepository.findMany(query);
  }

  async getProjectStatistics() {
    return await projectRepository.getStatistics();
  }
}

export const projectService = new ProjectService();

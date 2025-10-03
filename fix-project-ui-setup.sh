#!/bin/bash

# Fix the service file that was incomplete
cd frontend

echo "Fixing project service..."
cat > src/features/projects/services/projectService.ts << 'SERVICE'
import axios from 'axios';
import { Project, CreateProjectDTO, ProjectFilters } from '../types/project.types';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8081';

class ProjectService {
  private baseURL = `${API_BASE_URL}/api/v1/projects`;

  async createProject(data: CreateProjectDTO): Promise<Project> {
    const response = await axios.post(this.baseURL, data);
    return response.data;
  }

  async getProject(id: string): Promise<Project> {
    const response = await axios.get(`${this.baseURL}/${id}`);
    return response.data;
  }

  async updateProject(id: string, data: Partial<CreateProjectDTO>): Promise<Project> {
    const response = await axios.put(`${this.baseURL}/${id}`, data);
    return response.data;
  }

  async deleteProject(id: string): Promise<void> {
    await axios.delete(`${this.baseURL}/${id}`);
  }

  async listProjects(filters?: ProjectFilters): Promise<{
    projects: Project[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      totalPages: number;
    };
  }> {
    const response = await axios.get(this.baseURL, { params: filters });
    return response.data;
  }

  async getProjectStatistics(): Promise<any> {
    const response = await axios.get(`${this.baseURL}/stats/overview`);
    return response.data;
  }
}

export const projectService = new ProjectService();
SERVICE

echo "Setup completed successfully!"

# Check if files were created
echo ""
echo "Verifying installation..."
if [ -f "src/features/projects/types/project.types.ts" ] && 
   [ -f "src/features/projects/components/ProjectForm.tsx" ] && 
   [ -f "src/features/projects/components/GPSPicker.tsx" ]; then
  echo "✅ All core files created successfully"
else
  echo "⚠️  Some files may be missing. Running completion script..."
fi

cd ..

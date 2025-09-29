export interface Project {
  id: string;
  projectId: string;
  name: string;
  description?: string;
  status: ProjectStatus;
  priority: ProjectPriority;
  budget?: number;
  startDate?: string;
  endDate?: string;
  actualStartDate?: string;
  actualEndDate?: string;
  progress: number;
  location?: string;
  gpsLatitude?: number;
  gpsLongitude?: number;
  projectManager?: string;
  teamMembers: string[];
  stakeholders: string[];
  tags: string[];
  attachments: string[];
  risks?: any;
  milestones?: any;
  createdAt: string;
  updatedAt: string;
  createdBy?: string;
  updatedBy?: string;
}

export enum ProjectStatus {
  PLANNING = 'PLANNING',
  IN_PROGRESS = 'IN_PROGRESS',
  ON_HOLD = 'ON_HOLD',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED'
}

export enum ProjectPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL'
}

export interface CreateProjectDTO {
  name: string;
  description?: string;
  status?: ProjectStatus;
  priority?: ProjectPriority;
  budget?: number;
  startDate?: string;
  endDate?: string;
  location?: string;
  gpsLatitude?: number;
  gpsLongitude?: number;
  projectManager?: string;
  teamMembers?: string[];
  stakeholders?: string[];
  tags?: string[];
}

export interface ProjectFilters {
  page?: number;
  limit?: number;
  status?: ProjectStatus;
  priority?: ProjectPriority;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

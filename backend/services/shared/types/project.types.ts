export interface Project {
  id: string;
  projectId: string;
  name: string;
  description?: string;
  status: ProjectStatus;
  priority: ProjectPriority;
  budget?: number;
  startDate?: Date;
  endDate?: Date;
  actualStartDate?: Date;
  actualEndDate?: Date;
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
  createdAt: Date;
  updatedAt: Date;
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

export interface UpdateProjectDTO extends Partial<CreateProjectDTO> {
  actualStartDate?: string;
  actualEndDate?: string;
  progress?: number;
}

#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    Setting Up Project Registration UI         ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

cd frontend

# Install required dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
npm install mapbox-gl @types/mapbox-gl react-map-gl
npm install react-hook-form @hookform/resolvers zod
npm install @radix-ui/react-dialog @radix-ui/react-select
npm install date-fns react-datepicker @types/react-datepicker
npm install axios @tanstack/react-query
npm install zustand
npm install lucide-react

# Create directory structure
echo -e "${GREEN}Creating directory structure...${NC}"
mkdir -p src/features/projects/{components,hooks,services,store,types}
mkdir -p src/lib
mkdir -p app/\(dashboard\)/projects/{new,\[id\]}

# Create TypeScript types
echo -e "${GREEN}Creating project types...${NC}"
cat > src/features/projects/types/project.types.ts << 'TYPES'
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
TYPES

# Create Mapbox configuration
echo -e "${GREEN}Creating Mapbox configuration...${NC}"
cat > src/lib/mapbox.ts << 'MAPBOX'
export const MAPBOX_TOKEN = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || '';

export const MAPBOX_DEFAULTS = {
  center: {
    longitude: -122.4194,
    latitude: 37.7749
  },
  zoom: 10,
  style: 'mapbox://styles/mapbox/streets-v12'
};

export function validateMapboxToken(): boolean {
  if (!MAPBOX_TOKEN) {
    console.warn('Mapbox token is not configured. Set NEXT_PUBLIC_MAPBOX_TOKEN in your .env.local file');
    return false;
  }
  return true;
}
MAPBOX

# Create API service
echo -e "${GREEN}Creating project service...${NC}"
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
SERVICES

# Create Zustand store
echo -e "${GREEN}Creating project store...${NC}"
cat > src/features/projects/store/projectStore.ts << 'STORE'
import { create } from 'zustand';
import { Project, CreateProjectDTO, ProjectFilters } from '../types/project.types';
import { projectService } from '../services/projectService';

interface ProjectStore {
  projects: Project[];
  currentProject: Project | null;
  loading: boolean;
  error: string | null;
  filters: ProjectFilters;
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  } | null;

  // Actions
  createProject: (data: CreateProjectDTO) => Promise<Project>;
  fetchProjects: (filters?: ProjectFilters) => Promise<void>;
  fetchProject: (id: string) => Promise<void>;
  updateProject: (id: string, data: Partial<CreateProjectDTO>) => Promise<void>;
  deleteProject: (id: string) => Promise<void>;
  setFilters: (filters: ProjectFilters) => void;
  clearError: () => void;
}

export const useProjectStore = create<ProjectStore>((set, get) => ({
  projects: [],
  currentProject: null,
  loading: false,
  error: null,
  filters: {
    page: 1,
    limit: 20,
    sortBy: 'createdAt',
    sortOrder: 'desc'
  },
  pagination: null,

  createProject: async (data) => {
    set({ loading: true, error: null });
    try {
      const project = await projectService.createProject(data);
      set(state => ({
        projects: [project, ...state.projects],
        loading: false
      }));
      return project;
    } catch (error: any) {
      set({ loading: false, error: error.message });
      throw error;
    }
  },

  fetchProjects: async (filters) => {
    set({ loading: true, error: null });
    try {
      const response = await projectService.listProjects(filters || get().filters);
      set({
        projects: response.projects,
        pagination: response.pagination,
        loading: false
      });
    } catch (error: any) {
      set({ loading: false, error: error.message });
    }
  },

  fetchProject: async (id) => {
    set({ loading: true, error: null });
    try {
      const project = await projectService.getProject(id);
      set({ currentProject: project, loading: false });
    } catch (error: any) {
      set({ loading: false, error: error.message });
    }
  },

  updateProject: async (id, data) => {
    set({ loading: true, error: null });
    try {
      const updated = await projectService.updateProject(id, data);
      set(state => ({
        projects: state.projects.map(p => p.id === id ? updated : p),
        currentProject: state.currentProject?.id === id ? updated : state.currentProject,
        loading: false
      }));
    } catch (error: any) {
      set({ loading: false, error: error.message });
    }
  },

  deleteProject: async (id) => {
    set({ loading: true, error: null });
    try {
      await projectService.deleteProject(id);
      set(state => ({
        projects: state.projects.filter(p => p.id !== id),
        loading: false
      }));
    } catch (error: any) {
      set({ loading: false, error: error.message });
    }
  },

  setFilters: (filters) => {
    set({ filters });
  },

  clearError: () => {
    set({ error: null });
  }
}));
STORE

# Create GPS Picker component
echo -e "${GREEN}Creating GPS Picker component...${NC}"
cat > src/features/projects/components/GPSPicker.tsx << 'GPSPICKER'
'use client';

import React, { useState, useCallback, useEffect } from 'react';
import Map, { Marker, NavigationControl, GeolocateControl } from 'react-map-gl';
import { MapPin } from 'lucide-react';
import { MAPBOX_TOKEN, MAPBOX_DEFAULTS, validateMapboxToken } from '@/lib/mapbox';
import 'mapbox-gl/dist/mapbox-gl.css';

interface GPSPickerProps {
  latitude?: number;
  longitude?: number;
  onLocationSelect: (lat: number, lng: number) => void;
  disabled?: boolean;
}

export function GPSPicker({ 
  latitude, 
  longitude, 
  onLocationSelect, 
  disabled = false 
}: GPSPickerProps) {
  const [viewState, setViewState] = useState({
    longitude: longitude || MAPBOX_DEFAULTS.center.longitude,
    latitude: latitude || MAPBOX_DEFAULTS.center.latitude,
    zoom: MAPBOX_DEFAULTS.zoom
  });

  const [markerPosition, setMarkerPosition] = useState<{
    longitude: number;
    latitude: number;
  } | null>(
    latitude && longitude ? { latitude, longitude } : null
  );

  const [mapError, setMapError] = useState<string | null>(null);

  useEffect(() => {
    if (!validateMapboxToken()) {
      setMapError('Mapbox token is not configured. Please add NEXT_PUBLIC_MAPBOX_TOKEN to your environment variables.');
    }
  }, []);

  const handleMapClick = useCallback((event: any) => {
    if (disabled) return;
    
    const { lng, lat } = event.lngLat;
    setMarkerPosition({ longitude: lng, latitude: lat });
    onLocationSelect(lat, lng);
  }, [disabled, onLocationSelect]);

  if (mapError) {
    return (
      <div className="w-full h-64 bg-gray-100 rounded-lg flex items-center justify-center">
        <div className="text-center p-4">
          <MapPin className="w-12 h-12 text-gray-400 mx-auto mb-2" />
          <p className="text-sm text-gray-600">{mapError}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full h-64 rounded-lg overflow-hidden border border-gray-300">
      <Map
        {...viewState}
        onMove={evt => setViewState(evt.viewState)}
        onClick={handleMapClick}
        mapStyle={MAPBOX_DEFAULTS.style}
        mapboxAccessToken={MAPBOX_TOKEN}
        style={{ width: '100%', height: '100%' }}
        interactive={!disabled}
      >
        <NavigationControl position="top-right" />
        <GeolocateControl position="top-right" />
        
        {markerPosition && (
          <Marker
            longitude={markerPosition.longitude}
            latitude={markerPosition.latitude}
            anchor="bottom"
          >
            <MapPin className="w-8 h-8 text-red-500" />
          </Marker>
        )}
      </Map>
    </div>
  );
}
GPSPICKER

# Create Project Form component
echo -e "${GREEN}Creating Project Form component...${NC}"
cat > src/features/projects/components/ProjectForm.tsx << 'PROJECTFORM'
'use client';

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Calendar, MapPin, Users, Tag, DollarSign } from 'lucide-react';
import { GPSPicker } from './GPSPicker';
import { CreateProjectDTO, ProjectStatus, ProjectPriority } from '../types/project.types';

const projectSchema = z.object({
  name: z.string().min(3, 'Name must be at least 3 characters'),
  description: z.string().optional(),
  status: z.nativeEnum(ProjectStatus).optional(),
  priority: z.nativeEnum(ProjectPriority).optional(),
  budget: z.number().positive().optional().or(z.string().transform(v => v ? parseFloat(v) : undefined)),
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  location: z.string().optional(),
  gpsLatitude: z.number().optional(),
  gpsLongitude: z.number().optional(),
  projectManager: z.string().optional(),
  teamMembers: z.array(z.string()).optional(),
  stakeholders: z.array(z.string()).optional(),
  tags: z.array(z.string()).optional()
});

type ProjectFormData = z.infer<typeof projectSchema>;

interface ProjectFormProps {
  onSubmit: (data: CreateProjectDTO) => Promise<void>;
  initialData?: Partial<ProjectFormData>;
  isLoading?: boolean;
}

export function ProjectForm({ onSubmit, initialData, isLoading }: ProjectFormProps) {
  const [teamMembers, setTeamMembers] = useState<string[]>(initialData?.teamMembers || []);
  const [stakeholders, setStakeholders] = useState<string[]>(initialData?.stakeholders || []);
  const [tags, setTags] = useState<string[]>(initialData?.tags || []);

  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors }
  } = useForm<ProjectFormData>({
    resolver: zodResolver(projectSchema),
    defaultValues: {
      status: ProjectStatus.PLANNING,
      priority: ProjectPriority.MEDIUM,
      ...initialData
    }
  });

  const handleLocationSelect = (lat: number, lng: number) => {
    setValue('gpsLatitude', lat);
    setValue('gpsLongitude', lng);
  };

  const handleFormSubmit = async (data: ProjectFormData) => {
    await onSubmit({
      ...data,
      teamMembers,
      stakeholders,
      tags
    } as CreateProjectDTO);
  };

  const addItem = (item: string, setter: React.Dispatch<React.SetStateAction<string[]>>, list: string[]) => {
    if (item && !list.includes(item)) {
      setter([...list, item]);
    }
  };

  const removeItem = (index: number, setter: React.Dispatch<React.SetStateAction<string[]>>, list: string[]) => {
    setter(list.filter((_, i) => i !== index));
  };

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
      {/* Basic Information */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Basic Information</h3>
        
        <div>
          <label className="block text-sm font-medium mb-1">Project Name *</label>
          <input
            {...register('name')}
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter project name"
          />
          {errors.name && (
            <p className="text-red-500 text-sm mt-1">{errors.name.message}</p>
          )}
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">Description</label>
          <textarea
            {...register('description')}
            rows={4}
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter project description"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">Status</label>
            <select
              {...register('status')}
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {Object.values(ProjectStatus).map(status => (
                <option key={status} value={status}>
                  {status.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Priority</label>
            <select
              {...register('priority')}
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {Object.values(ProjectPriority).map(priority => (
                <option key={priority} value={priority}>{priority}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Schedule & Budget */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Schedule & Budget</h3>
        
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              <Calendar className="inline w-4 h-4 mr-1" />
              Start Date
            </label>
            <input
              type="date"
              {...register('startDate')}
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              <Calendar className="inline w-4 h-4 mr-1" />
              End Date
            </label>
            <input
              type="date"
              {...register('endDate')}
              className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">
            <DollarSign className="inline w-4 h-4 mr-1" />
            Budget
          </label>
          <input
            type="number"
            step="0.01"
            {...register('budget')}
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter budget amount"
          />
        </div>
      </div>

      {/* Location */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">
          <MapPin className="inline w-5 h-5 mr-1" />
          Location
        </h3>
        
        <div>
          <label className="block text-sm font-medium mb-1">Address/Location</label>
          <input
            {...register('location')}
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter location"
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1">GPS Coordinates</label>
          <GPSPicker
            latitude={watch('gpsLatitude')}
            longitude={watch('gpsLongitude')}
            onLocationSelect={handleLocationSelect}
            disabled={isLoading}
          />
          <div className="mt-2 text-sm text-gray-600">
            {watch('gpsLatitude') && watch('gpsLongitude') && (
              <span>
                Lat: {watch('gpsLatitude')?.toFixed(6)}, 
                Lng: {watch('gpsLongitude')?.toFixed(6)}
              </span>
            )}
          </div>
        </div>
      </div>

      {/* Team */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold">
          <Users className="inline w-5 h-5 mr-1" />
          Team
        </h3>
        
        <div>
          <label className="block text-sm font-medium mb-1">Project Manager</label>
          <input
            {...register('projectManager')}
            className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter project manager name"
          />
        </div>
      </div>

      {/* Submit Button */}
      <div className="pt-4">
        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
        >
          {isLoading ? 'Creating...' : 'Create Project'}
        </button>
      </div>
    </form>
  );
}
PROJECTFORM

# Create Slide Panel component
echo -e "${GREEN}Creating Slide Panel component...${NC}"
cat > src/features/projects/components/ProjectSlidePanel.tsx << 'SLIDEPANEL'
'use client';

import React from 'react';
import * as Dialog from '@radix-ui/react-dialog';
import { X } from 'lucide-react';

interface ProjectSlidePanelProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

export function ProjectSlidePanel({ 
  isOpen, 
  onClose, 
  title, 
  children 
}: ProjectSlidePanelProps) {
  return (
    <Dialog.Root open={isOpen} onOpenChange={onClose}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/50 z-40" />
        <Dialog.Content className="fixed right-0 top-0 h-full w-full max-w-2xl bg-white shadow-xl z-50 overflow-y-auto">
          <div className="sticky top-0 bg-white border-b px-6 py-4 flex items-center justify-between">
            <Dialog.Title className="text-xl font-semibold">
              {title}
            </Dialog.Title>
            <Dialog.Close asChild>
              <button
                className="p-2 hover:bg-gray-100 rounded-lg"
                aria-label="Close"
              >
                <X className="w-5 h-5" />
              </button>
            </Dialog.Close>
          </div>
          
          <div className="p-6">
            {children}
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
SLIDEPANEL

# Create useProjects hook
echo -e "${GREEN}Creating useProjects hook...${NC}"
cat > src/features/projects/hooks/useProjects.ts << 'USEPROJECTS'
'use client';

import { useEffect } from 'react';
import { useProjectStore } from '../store/projectStore';
import { CreateProjectDTO, ProjectFilters } from '../types/project.types';

export function useProjects(filters?: ProjectFilters) {
  const {
    projects,
    loading,
    error,
    pagination,
    fetchProjects,
    createProject,
    updateProject,
    deleteProject,
    clearError
  } = useProjectStore();

  useEffect(() => {
    fetchProjects(filters);
  }, [filters]);

  return {
    projects,
    loading,
    error,
    pagination,
    createProject,
    updateProject,
    deleteProject,
    clearError,
    refetch: () => fetchProjects(filters)
  };
}

export function useProject(id: string) {
  const {
    currentProject,
    loading,
    error,
    fetchProject,
    updateProject
  } = useProjectStore();

  useEffect(() => {
    if (id) {
      fetchProject(id);
    }
  }, [id]);

  return {
    project: currentProject,
    loading,
    error,
    updateProject
  };
}
USEPROJECTS

# Create Projects List Page
echo -e "${GREEN}Creating Projects List Page...${NC}"
cat > app/\(dashboard\)/projects/page.tsx << 'LISTPAGE'
'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Plus, Search, Filter, MapPin, Calendar, DollarSign } from 'lucide-react';
import { useProjects } from '@/features/projects/hooks/useProjects';
import { ProjectStatus, ProjectPriority } from '@/features/projects/types/project.types';
import { ProjectSlidePanel } from '@/features/projects/components/ProjectSlidePanel';
import { ProjectForm } from '@/features/projects/components/ProjectForm';
import { useProjectStore } from '@/features/projects/store/projectStore';

export default function ProjectsPage() {
  const [isCreatePanelOpen, setIsCreatePanelOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<ProjectStatus | ''>('');
  
  const { projects, loading, error, pagination, refetch } = useProjects({
    search: searchTerm,
    status: statusFilter as ProjectStatus || undefined
  });

  const { createProject } = useProjectStore();

  const handleCreateProject = async (data: any) => {
    try {
      await createProject(data);
      setIsCreatePanelOpen(false);
      refetch();
    } catch (error) {
      console.error('Failed to create project:', error);
    }
  };

  const getStatusColor = (status: ProjectStatus) => {
    const colors = {
      PLANNING: 'bg-blue-100 text-blue-800',
      IN_PROGRESS: 'bg-green-100 text-green-800',
      ON_HOLD: 'bg-yellow-100 text-yellow-800',
      COMPLETED: 'bg-gray-100 text-gray-800',
      CANCELLED: 'bg-red-100 text-red-800'
    };
    return colors[status] || 'bg-gray-100 text-gray-800';
  };

  const getPriorityColor = (priority: ProjectPriority) => {
    const colors = {
      LOW: 'bg-gray-100 text-gray-800',
      MEDIUM: 'bg-blue-100 text-blue-800',
      HIGH: 'bg-orange-100 text-orange-800',
      CRITICAL: 'bg-red-100 text-red-800'
    };
    return colors[priority] || 'bg-gray-100 text-gray-800';
  };

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Projects</h1>
        <p className="text-gray-600 mt-1">Manage and track all your engineering projects</p>
      </div>

      {/* Actions Bar */}
      <div className="bg-white rounded-lg shadow mb-6 p-4">
        <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
          <div className="flex gap-4 flex-1">
            {/* Search */}
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Search projects..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            {/* Status Filter */}
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value as ProjectStatus | '')}
              className="px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Status</option>
              {Object.values(ProjectStatus).map(status => (
                <option key={status} value={status}>
                  {status.replace('_', ' ')}
                </option>
              ))}
            </select>
          </div>

          {/* Create Button */}
          <button
            onClick={() => setIsCreatePanelOpen(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <Plus className="w-5 h-5" />
            New Project
          </button>
        </div>
      </div>

      {/* Projects Grid */}
      {loading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading projects...</p>
        </div>
      ) : error ? (
        <div className="text-center py-12">
          <p className="text-red-600">Error: {error}</p>
        </div>
      ) : projects.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <p className="text-gray-600">No projects found</p>
          <button
            onClick={() => setIsCreatePanelOpen(true)}
            className="mt-4 bg-blue-600 text-white px-6 text-white px-4 py-2 rounded-lg hover:bg-blue-700"
          >
            Create your first project
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {projects.map((project) => (
            <Link
              key={project.id}
              href={`/projects/${project.id}`}
              className="bg-white rounded-lg shadow hover:shadow-lg transition-shadow p-6"
            >
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">{project.name}</h3>
                  <p className="text-sm text-gray-500">{project.projectId}</p>
                </div>
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(project.status)}`}>
                  {project.status.replace('_', ' ')}
                </span>
              </div>

              {project.description && (
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  {project.description}
                </p>
              )}

              <div className="space-y-2">
                {project.location && (
                  <div className="flex items-center text-sm text-gray-600">
                    <MapPin className="w-4 h-4 mr-2" />
                    <span className="truncate">{project.location}</span>
                  </div>
                )}

                {project.startDate && (
                  <div className="flex items-center text-sm text-gray-600">
                    <Calendar className="w-4 h-4 mr-2" />
                    <span>{new Date(project.startDate).toLocaleDateString()}</span>
                  </div>
                )}

                {project.budget && (
                  <div className="flex items-center text-sm text-gray-600">
                    <DollarSign className="w-4 h-4 mr-2" />
                    <span>${project.budget.toLocaleString()}</span>
                  </div>
                )}
              </div>

              <div className="mt-4 flex items-center justify-between">
                <span className={`px-2 py-1 rounded text-xs font-medium ${getPriorityColor(project.priority)}`}>
                  {project.priority}
                </span>
                <div className="flex items-center">
                  <div className="w-full bg-gray-200 rounded-full h-2 w-24">
                    <div 
                      className="bg-blue-600 h-2 rounded-full"
                      style={{ width: `${project.progress}%` }}
                    />
                  </div>
                  <span className="ml-2 text-xs text-gray-600">{project.progress}%</span>
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}

      {/* Pagination */}
      {pagination && pagination.totalPages > 1 && (
        <div className="mt-6 flex justify-center">
          <nav className="flex gap-2">
            {Array.from({ length: pagination.totalPages }, (_, i) => i + 1).map(page => (
              <button
                key={page}
                className={`px-4 py-2 rounded-lg ${
                  pagination.page === page 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-white text-gray-700 hover:bg-gray-100'
                }`}
              >
                {page}
              </button>
            ))}
          </nav>
        </div>
      )}

      {/* Create Project Slide Panel */}
      <ProjectSlidePanel
        isOpen={isCreatePanelOpen}
        onClose={() => setIsCreatePanelOpen(false)}
        title="Create New Project"
      >
        <ProjectForm 
          onSubmit={handleCreateProject}
          isLoading={loading}
        />
      </ProjectSlidePanel>
    </div>
  );
}
LISTPAGE

# Create New Project Page
echo -e "${GREEN}Creating New Project Page...${NC}"
cat > app/\(dashboard\)/projects/new/page.tsx << 'NEWPAGE'
'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { ArrowLeft } from 'lucide-react';
import { ProjectForm } from '@/features/projects/components/ProjectForm';
import { useProjectStore } from '@/features/projects/store/projectStore';

export default function NewProjectPage() {
  const router = useRouter();
  const { createProject } = useProjectStore();
  const [isLoading, setIsLoading] = React.useState(false);

  const handleSubmit = async (data: any) => {
    try {
      setIsLoading(true);
      const project = await createProject(data);
      router.push(`/projects/${project.id}`);
    } catch (error) {
      console.error('Failed to create project:', error);
      setIsLoading(false);
    }
  };

  return (
    <div className="max-w-4xl mx-auto p-6">
      <button
        onClick={() => router.back()}
        className="mb-6 flex items-center text-gray-600 hover:text-gray-900"
      >
        <ArrowLeft className="w-5 h-5 mr-2" />
        Back to Projects
      </button>

      <div className="bg-white rounded-lg shadow-lg p-6">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">Create New Project</h1>
        
        <ProjectForm 
          onSubmit={handleSubmit}
          isLoading={isLoading}
        />
      </div>
    </div>
  );
}
NEWPAGE

# Create Project Details Page
echo -e "${GREEN}Creating Project Details Page...${NC}"
cat > app/\(dashboard\)/projects/\[id\]/page.tsx << 'DETAILPAGE'
'use client';

import React, { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Edit, Trash2, MapPin, Calendar, Users, DollarSign } from 'lucide-react';
import { useProject } from '@/features/projects/hooks/useProjects';
import { useProjectStore } from '@/features/projects/store/projectStore';
import { ProjectSlidePanel } from '@/features/projects/components/ProjectSlidePanel';
import { ProjectForm } from '@/features/projects/components/ProjectForm';

export default function ProjectDetailsPage() {
  const params = useParams();
  const router = useRouter();
  const projectId = params.id as string;
  
  const { project, loading, error, updateProject } = useProject(projectId);
  const { deleteProject } = useProjectStore();
  
  const [isEditPanelOpen, setIsEditPanelOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleUpdate = async (data: any) => {
    try {
      await updateProject(projectId, data);
      setIsEditPanelOpen(false);
    } catch (error) {
      console.error('Failed to update project:', error);
    }
  };

  const handleDelete = async () => {
    if (confirm('Are you sure you want to delete this project?')) {
      try {
        setIsDeleting(true);
        await deleteProject(projectId);
        router.push('/projects');
      } catch (error) {
        console.error('Failed to delete project:', error);
        setIsDeleting(false);
      }
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error || !project) {
    return (
      <div className="p-6">
        <div className="bg-red-50 text-red-600 p-4 rounded-lg">
          Error: {error || 'Project not found'}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex justify-between items-start">
        <div>
          <button
            onClick={() => router.push('/projects')}
            className="mb-4 flex items-center text-gray-600 hover:text-gray-900"
          >
            <ArrowLeft className="w-5 h-5 mr-2" />
            Back to Projects
          </button>
          <h1 className="text-3xl font-bold text-gray-900">{project.name}</h1>
          <p className="text-gray-600 mt-1">{project.projectId}</p>
        </div>
        
        <div className="flex gap-2">
          <button
            onClick={() => setIsEditPanelOpen(true)}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center gap-2"
          >
            <Edit className="w-4 h-4" />
            Edit
          </button>
          <button
            onClick={handleDelete}
            disabled={isDeleting}
            className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 flex items-center gap-2 disabled:opacity-50"
          >
            <Trash2 className="w-4 h-4" />
            {isDeleting ? 'Deleting...' : 'Delete'}
          </button>
        </div>
      </div>

      {/* Project Details */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Main Info */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4">Project Information</h2>
            
            {project.description && (
              <div className="mb-4">
                <h3 className="text-sm font-medium text-gray-500 mb-1">Description</h3>
                <p className="text-gray-700">{project.description}</p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-4">
              <div>
                <h3 className="text-sm font-medium text-gray-500 mb-1">Status</h3>
                <span className="px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                  {project.status.replace('_', ' ')}
                </span>
              </div>
              
              <div>
                <h3 className="text-sm font-medium text-gray-500 mb-1">Priority</h3>
                <span className="px-3 py-1 rounded-full text-sm font-medium bg-orange-100 text-orange-800">
                  {project.priority}
                </span>
              </div>

              <div>
                <h3 className="text-sm font-medium text-gray-500 mb-1">Progress</h3>
                <div className="flex items-center">
                  <div className="w-full bg-gray-200 rounded-full h-2 mr-2">
                    <div 
                      className="bg-blue-600 h-2 rounded-full"
                      style={{ width: `${project.progress}%` }}
                    />
                  </div>
                  <span className="text-sm font-medium">{project.progress}%</span>
                </div>
              </div>
            </div>
          </div>

          {/* Location */}
          {(project.location || project.gpsLatitude) && (
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-semibold mb-4 flex items-center">
                <MapPin className="w-5 h-5 mr-2" />
                Location
              </h2>
              
              {project.location && (
                <p className="text-gray-700 mb-2">{project.location}</p>
              )}
              
              {project.gpsLatitude && project.gpsLongitude && (
                <p className="text-sm text-gray-600">
                  GPS: {project.gpsLatitude.toFixed(6)}, {project.gpsLongitude.toFixed(6)}
                </p>
              )}
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Schedule */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <Calendar className="w-5 h-5 mr-2" />
              Schedule
            </h2>
            
            <div className="space-y-3">
              {project.startDate && (
                <div>
                  <p className="text-sm text-gray-500">Start Date</p>
                  <p className="font-medium">{new Date(project.startDate).toLocaleDateString()}</p>
                </div>
              )}
              
              {project.endDate && (
                <div>
                  <p className="text-sm text-gray-500">End Date</p>
                  <p className="font-medium">{new Date(project.endDate).toLocaleDateString()}</p>
                </div>
              )}
            </div>
          </div>

          {/* Budget */}
          {project.budget && (
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-semibold mb-4 flex items-center">
                <DollarSign className="w-5 h-5 mr-2" />
                Budget
              </h2>
              <p className="text-2xl font-bold text-green-600">
                ${project.budget.toLocaleString()}
              </p>
            </div>
          )}

          {/* Team */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold mb-4 flex items-center">
              <Users className="w-5 h-5 mr-2" />
              Team
            </h2>
            
            {project.projectManager && (
              <div className="mb-3">
                <p className="text-sm text-gray-500">Project Manager</p>
                <p className="font-medium">{project.projectManager}</p>
              </div>
            )}
            
            {project.teamMembers.length > 0 && (
              <div>
                <p className="text-sm text-gray-500 mb-2">Team Members</p>
                <div className="flex flex-wrap gap-2">
                  {project.teamMembers.map((member, index) => (
                    <span key={index} className="px-2 py-1 bg-gray-100 rounded text-sm">
                      {member}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Edit Panel */}
      <ProjectSlidePanel
        isOpen={isEditPanelOpen}
        onClose={() => setIsEditPanelOpen(false)}
        title="Edit Project"
      >
        <ProjectForm 
          onSubmit={handleUpdate}
          initialData={project}
          isLoading={loading}
        />
      </ProjectSlidePanel>
    </div>
  );
}
DETAILPAGE

# Update environment variables
echo -e "${GREEN}Adding environment variables...${NC}"
cat >> .env.local << 'ENV'

# Mapbox Configuration
NEXT_PUBLIC_MAPBOX_TOKEN=your_mapbox_token_here

# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8081
ENV

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}    Project Registration UI Setup Complete!    ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${YELLOW}Important Configuration Steps:${NC}"
echo ""
echo -e "1. ${BLUE}Get a Mapbox Access Token:${NC}"
echo "   - Go to https://www.mapbox.com/"
echo "   - Create a free account"
echo "   - Copy your default public token"
echo ""
echo -e "2. ${BLUE}Update your .env.local file:${NC}"
echo "   - Replace 'your_mapbox_token_here' with your actual token"
echo "   - Ensure NEXT_PUBLIC_API_URL points to your backend (default: http://localhost:8081)"
echo ""
echo -e "3. ${BLUE}Start the services:${NC}"
echo "   - Backend: cd backend/services/project-service && npm run dev"
echo "   - Frontend: cd frontend && npm run dev"
echo ""
echo -e "${GREEN}Features Implemented:${NC}"
echo "  ✅ Project registration form with validation"
echo "  ✅ GPS coordinate picker with Mapbox integration"
echo "  ✅ Slide panel for project creation"
echo "  ✅ Project listing with search and filters"
echo "  ✅ Project details page with edit/delete"
echo "  ✅ Auto-generated project IDs (DIR-YYYY-XXXX)"
echo "  ✅ Comprehensive field support"
echo "  ✅ State management with Zustand"
echo ""
echo -e "${YELLOW}Access the UI at:${NC}"
echo "  http://localhost:3000/projects"

cd ..

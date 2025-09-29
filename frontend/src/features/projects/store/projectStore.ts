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

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

#!/bin/bash

cd frontend

echo "Creating missing Project UI files..."

# Create Zustand store
echo "Creating project store..."
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
echo "Creating GPS Picker component..."
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

# Create Slide Panel component
echo "Creating Slide Panel component..."
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
echo "Creating useProjects hook..."
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

echo ""
echo "✅ All missing files have been created!"
echo ""
echo "Verifying all files are now present..."
FILES=(
  "src/features/projects/types/project.types.ts"
  "src/features/projects/services/projectService.ts"
  "src/features/projects/store/projectStore.ts"
  "src/features/projects/components/GPSPicker.tsx"
  "src/features/projects/components/ProjectSlidePanel.tsx"
  "src/features/projects/components/ProjectForm.tsx"
  "src/features/projects/hooks/useProjects.ts"
  "src/lib/mapbox.ts"
)

ALL_PRESENT=true
for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "❌ Missing: $FILE"
    ALL_PRESENT=false
  else
    echo "✅ Found: $FILE"
  fi
done

if $ALL_PRESENT; then
  echo ""
  echo "🎉 Project UI setup is complete!"
  echo ""
  echo "Next steps:"
  echo "1. Get a Mapbox token from https://www.mapbox.com/"
  echo "2. Update NEXT_PUBLIC_MAPBOX_TOKEN in frontend/.env.local"
  echo "3. Start the backend: cd backend/services/project-service && npm run dev"
  echo "4. Start the frontend: cd frontend && npm run dev"
  echo "5. Access the app at http://localhost:3000/projects"
fi

cd ..

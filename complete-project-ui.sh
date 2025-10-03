#!/bin/bash

cd frontend

echo "Completing Project UI setup..."

# Ensure all directories exist
mkdir -p src/features/projects/{components,hooks,services,store,types}
mkdir -p src/lib
mkdir -p app/\(dashboard\)/projects/{new,\[id\]}

# Check and create missing components
if [ ! -f "src/features/projects/components/ProjectForm.tsx" ]; then
  echo "Creating ProjectForm component..."
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

  return (
    <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-6">
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

      <div className="space-y-4">
        <h3 className="text-lg font-semibold">Location</h3>
        
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
        </div>
      </div>

      <div className="pt-4">
        <button
          type="submit"
          disabled={isLoading}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
        >
          {isLoading ? 'Creating...' : 'Create Project'}
        </button>
      </div>
    </form>
  );
}
PROJECTFORM
fi

# Check remaining files
echo "Checking all required files..."
FILES=(
  "src/features/projects/types/project.types.ts"
  "src/features/projects/services/projectService.ts"
  "src/features/projects/store/projectStore.ts"
  "src/features/projects/components/GPSPicker.tsx"
  "src/features/projects/components/ProjectSlidePanel.tsx"
  "src/features/projects/hooks/useProjects.ts"
  "src/lib/mapbox.ts"
)

MISSING=0
for FILE in "${FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "❌ Missing: $FILE"
    MISSING=$((MISSING + 1))
  else
    echo "✅ Found: $FILE"
  fi
done

if [ $MISSING -eq 0 ]; then
  echo ""
  echo "✅ All files are present!"
else
  echo ""
  echo "⚠️ $MISSING files are missing. Run the original setup script again."
fi

# Add environment variables if not present
if ! grep -q "NEXT_PUBLIC_MAPBOX_TOKEN" .env.local 2>/dev/null; then
  echo ""
  echo "Adding environment variables to .env.local..."
  cat >> .env.local << 'ENV'

# Mapbox Configuration
NEXT_PUBLIC_MAPBOX_TOKEN=your_mapbox_token_here

# API Configuration  
NEXT_PUBLIC_API_URL=http://localhost:8081
ENV
  echo "✅ Environment variables added"
fi

echo ""
echo "Setup verification complete!"
echo ""
echo "Next steps:"
echo "1. Get a Mapbox token from https://www.mapbox.com/"
echo "2. Update NEXT_PUBLIC_MAPBOX_TOKEN in frontend/.env.local"
echo "3. Start the backend: cd backend/services/project-service && npm run dev"
echo "4. Start the frontend: cd frontend && npm run dev"
echo "5. Access the app at http://localhost:3000/projects"

cd ..

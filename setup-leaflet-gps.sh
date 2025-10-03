#!/bin/bash

cd frontend

echo "Setting up Leaflet for GPS picking..."

# Install Leaflet dependencies
npm install leaflet react-leaflet @types/leaflet

# Create Leaflet configuration
echo "Creating Leaflet configuration..."
cat > src/lib/leaflet.ts << 'LEAFLET'
export const LEAFLET_DEFAULTS = {
  center: {
    lat: 37.7749,
    lng: -122.4194
  },
  zoom: 10
};

// Fix for Leaflet default marker icons in Next.js
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix marker icon issue with webpack
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});
LEAFLET

# Update GPS Picker to use Leaflet
echo "Creating Leaflet GPS Picker..."
cat > src/features/projects/components/GPSPicker.tsx << 'GPSPICKER'
'use client';

import React, { useState, useCallback } from 'react';
import dynamic from 'next/dynamic';
import { MapPin } from 'lucide-react';
import { LEAFLET_DEFAULTS } from '@/lib/leaflet';

// Dynamic import to avoid SSR issues
const MapContainer = dynamic(
  () => import('react-leaflet').then(mod => mod.MapContainer),
  { ssr: false }
);
const TileLayer = dynamic(
  () => import('react-leaflet').then(mod => mod.TileLayer),
  { ssr: false }
);
const Marker = dynamic(
  () => import('react-leaflet').then(mod => mod.Marker),
  { ssr: false }
);
const useMapEvents = dynamic(
  () => import('react-leaflet').then(mod => mod.useMapEvents),
  { ssr: false }
);

interface GPSPickerProps {
  latitude?: number;
  longitude?: number;
  onLocationSelect: (lat: number, lng: number) => void;
  disabled?: boolean;
}

function LocationMarker({ position, onLocationSelect, disabled }: any) {
  const [markerPosition, setMarkerPosition] = useState(position);
  
  const MapEvents = () => {
    // @ts-ignore
    useMapEvents({
      click(e: any) {
        if (!disabled) {
          const { lat, lng } = e.latlng;
          setMarkerPosition({ lat, lng });
          onLocationSelect(lat, lng);
        }
      },
    });
    return null;
  };

  return (
    <>
      <MapEvents />
      {markerPosition && <Marker position={[markerPosition.lat, markerPosition.lng]} />}
    </>
  );
}

export function GPSPicker({ 
  latitude, 
  longitude, 
  onLocationSelect, 
  disabled = false 
}: GPSPickerProps) {
  const center = {
    lat: latitude || LEAFLET_DEFAULTS.center.lat,
    lng: longitude || LEAFLET_DEFAULTS.center.lng
  };

  const [mounted, setMounted] = useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <div className="w-full h-64 bg-gray-100 rounded-lg flex items-center justify-center">
        <div className="text-center p-4">
          <MapPin className="w-12 h-12 text-gray-400 mx-auto mb-2" />
          <p className="text-sm text-gray-600">Loading map...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="w-full h-64 rounded-lg overflow-hidden border border-gray-300">
      <MapContainer
        center={[center.lat, center.lng]}
        zoom={LEAFLET_DEFAULTS.zoom}
        style={{ height: '100%', width: '100%' }}
        className="h-full w-full"
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <LocationMarker 
          position={latitude && longitude ? { lat: latitude, lng: longitude } : null}
          onLocationSelect={onLocationSelect}
          disabled={disabled}
        />
      </MapContainer>
      
      {latitude && longitude && (
        <div className="mt-2 text-sm text-gray-600">
          Lat: {latitude.toFixed(6)}, Lng: {longitude.toFixed(6)}
        </div>
      )}
    </div>
  );
}
GPSPICKER

# Create a simplified non-dynamic version as fallback
echo "Creating static GPS Picker fallback..."
cat > src/features/projects/components/GPSPickerStatic.tsx << 'STATIC'
'use client';

import React, { useState } from 'react';
import { MapPin } from 'lucide-react';

interface GPSPickerStaticProps {
  latitude?: number;
  longitude?: number;
  onLocationSelect: (lat: number, lng: number) => void;
  disabled?: boolean;
}

export function GPSPickerStatic({ 
  latitude, 
  longitude, 
  onLocationSelect, 
  disabled = false 
}: GPSPickerStaticProps) {
  const [lat, setLat] = useState(latitude?.toString() || '');
  const [lng, setLng] = useState(longitude?.toString() || '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const latNum = parseFloat(lat);
    const lngNum = parseFloat(lng);
    
    if (!isNaN(latNum) && !isNaN(lngNum)) {
      if (latNum >= -90 && latNum <= 90 && lngNum >= -180 && lngNum <= 180) {
        onLocationSelect(latNum, lngNum);
      }
    }
  };

  return (
    <div className="w-full space-y-4">
      <div className="bg-gray-100 rounded-lg p-4">
        <div className="flex items-center justify-center mb-4">
          <MapPin className="w-8 h-8 text-gray-400" />
        </div>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Latitude</label>
              <input
                type="number"
                step="0.000001"
                min="-90"
                max="90"
                value={lat}
                onChange={(e) => setLat(e.target.value)}
                disabled={disabled}
                className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="37.7749"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Longitude</label>
              <input
                type="number"
                step="0.000001"
                min="-180"
                max="180"
                value={lng}
                onChange={(e) => setLng(e.target.value)}
                disabled={disabled}
                className="w-full px-3 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="-122.4194"
              />
            </div>
          </div>
          <button
            type="submit"
            disabled={disabled}
            className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
          >
            Set Location
          </button>
        </form>
      </div>
      <p className="text-sm text-gray-600">
        Click "Set Location" after entering coordinates, or use the interactive map above (if available)
      </p>
    </div>
  );
}
STATIC

# Update environment file to remove Mapbox requirement
echo "Updating environment configuration..."
if grep -q "NEXT_PUBLIC_MAPBOX_TOKEN" .env.local 2>/dev/null; then
  sed -i '/NEXT_PUBLIC_MAPBOX_TOKEN/d' .env.local
  echo "Removed Mapbox token requirement from .env.local"
fi

# Add Leaflet CSS import to global styles
if ! grep -q "leaflet/dist/leaflet.css" app/globals.css 2>/dev/null; then
  echo "/* Leaflet styles */" >> app/globals.css
  echo "@import 'leaflet/dist/leaflet.css';" >> app/globals.css
fi

echo ""
echo "✅ Leaflet GPS picker setup complete!"
echo ""
echo "Benefits of using Leaflet:"
echo "  ✅ No API key required"
echo "  ✅ Completely free to use"
echo "  ✅ Uses OpenStreetMap tiles"
echo "  ✅ Full GPS coordinate picking functionality"
echo ""
echo "Next steps:"
echo "1. Start the backend: cd backend/services/project-service && npm run dev"
echo "2. Start the frontend: cd frontend && npm run dev"
echo "3. Access the app at http://localhost:3000/projects"
echo ""
echo "No API tokens needed! 🎉"

cd ..

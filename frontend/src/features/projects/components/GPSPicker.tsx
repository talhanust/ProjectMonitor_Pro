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

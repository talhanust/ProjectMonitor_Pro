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

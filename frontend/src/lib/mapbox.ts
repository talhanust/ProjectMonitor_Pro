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

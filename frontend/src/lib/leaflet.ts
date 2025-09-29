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

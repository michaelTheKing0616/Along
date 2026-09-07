import type { SafetySlaConfig, SlaTier } from './types';

export function formatAgeSeconds(ageS: number): string {
  if (ageS < 60) return `${Math.max(0, Math.floor(ageS))}s`;
  const minutes = Math.floor(ageS / 60);
  const seconds = Math.floor(ageS % 60);
  if (minutes < 60) return `${minutes}m ${seconds}s`;
  const hours = Math.floor(minutes / 60);
  const remMin = minutes % 60;
  return `${hours}h ${remMin}m`;
}

export function slaTierForOpenSos(ageS: number, sla: SafetySlaConfig): SlaTier {
  if (ageS >= sla.escalateSlaS) return 'critical';
  if (ageS >= sla.ackSlaS) return 'warning';
  return 'normal';
}

export function slaTierLabel(tier: SlaTier): string {
  if (tier === 'critical') return 'Escalated';
  if (tier === 'warning') return 'Ack SLA';
  return 'On track';
}

export function parseGeoPoint(location: unknown): { lat: number; lng: number } | null {
  if (!location || typeof location !== 'object') return null;
  const geo = location as { type?: string; coordinates?: number[] };
  if (geo.type === 'Point' && Array.isArray(geo.coordinates) && geo.coordinates.length >= 2) {
    return { lng: geo.coordinates[0]!, lat: geo.coordinates[1]! };
  }
  return null;
}

export function formatCoordinates(lat: number | null, lng: number | null): string {
  if (lat == null || lng == null) return '—';
  return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
}

export function mapExternalUrl(lat: number, lng: number): string {
  return `https://www.openstreetmap.org/?mlat=${lat}&mlon=${lng}#map=17/${lat}/${lng}`;
}

export function incidentTypeLabel(type: string): string {
  return type.replace(/_/g, ' ');
}

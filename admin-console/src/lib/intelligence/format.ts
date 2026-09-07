import type {
  CandidateParkRow,
  GeometryCorrectionRow,
  RouteInferenceRow,
} from './types';

export function formatCoordinates(lat: number | null, lng: number | null): string {
  if (lat == null || lng == null) return '—';
  return `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
}

export function graphMapLink(citySlug: string, lat: number, lng: number): string {
  return `/${citySlug}/graph?lat=${lat.toFixed(5)}&lng=${lng.toFixed(5)}`;
}

export function parkStatusLabel(status: CandidateParkRow['status']): string {
  if (status === 'new') return 'Pending';
  if (status === 'promoted_to_stage') return 'Promoted';
  return 'Dismissed';
}

export function routeInferenceStatusLabel(status: RouteInferenceRow['status']): string {
  if (status === 'new') return 'Pending';
  if (status === 'promoted_to_route') return 'Promoted';
  return 'Dismissed';
}

export function geometryStatusLabel(status: GeometryCorrectionRow['status']): string {
  return status.replace(/_/g, ' ');
}

export function pendingParkRows(rows: CandidateParkRow[]): CandidateParkRow[] {
  return rows.filter((r) => r.status === 'new');
}

export function pendingRouteRows(rows: RouteInferenceRow[]): RouteInferenceRow[] {
  return rows.filter((r) => r.status === 'new');
}

export function pendingGeometryRows(rows: GeometryCorrectionRow[]): GeometryCorrectionRow[] {
  return rows.filter((r) => r.status === 'candidate');
}

import type { GraphVerificationStatus } from '@/lib/map/types';

export type GraphMapPoint = {
  id: string;
  name: string;
  lat: number;
  lng: number;
  verification_status: GraphVerificationStatus;
  route_id?: string;
  is_official_park?: boolean;
};

export type GraphMapRoute = {
  id: string;
  mode_code: string;
  verification_status: GraphVerificationStatus;
  coordinates: [number, number][];
};

export type PendingGraphChange =
  | {
      kind: 'park';
      id: string;
      label: string;
      payload: { name?: string; name_aliases?: string[]; lat?: number; lng?: number };
    }
  | {
      kind: 'route';
      id: string;
      label: string;
      payload: { name?: string | null; active?: boolean };
    }
  | {
      kind: 'route_stage';
      id: string;
      label: string;
      payload: { name?: string | null; sequence?: number; lat?: number; lng?: number };
    };

export function pendingChangeKey(change: PendingGraphChange): string {
  return `${change.kind}:${change.id}`;
}

export function rpcGraphType(kind: PendingGraphChange['kind']): string {
  return kind === 'route_stage' ? 'route_stage' : kind;
}

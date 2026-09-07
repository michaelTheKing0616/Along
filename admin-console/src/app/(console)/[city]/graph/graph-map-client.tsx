'use client';

import dynamic from 'next/dynamic';
import type { GraphMapPoint, GraphMapRoute } from '@/lib/graph/types';

const GraphMap = dynamic(
  () => import('@/components/along/GraphMap').then((mod) => mod.GraphMap),
  {
    ssr: false,
    loading: () => <div className="card" style={{ height: 420 }}>Loading graph map…</div>,
  }
);

export function GraphMapClient(props: {
  center: { lat: number; lng: number };
  parks: GraphMapPoint[];
  stages: GraphMapPoint[];
  routes: GraphMapRoute[];
  pendingStagePositions: Record<string, { lat: number; lng: number }>;
  onStageDrag: (stageId: string, lat: number, lng: number) => void;
  onSelectStage: (stageId: string) => void;
  onSelectPark: (parkId: string) => void;
}) {
  return <GraphMap {...props} />;
}

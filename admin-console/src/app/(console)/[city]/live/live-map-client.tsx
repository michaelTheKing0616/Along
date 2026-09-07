'use client';

import dynamic from 'next/dynamic';
import type { LiveMapStaticPayload } from '@/lib/map/types';

const AdminLiveMap = dynamic(
  () => import('@/components/along/AdminLiveMap').then((mod) => mod.AdminLiveMap),
  {
    ssr: false,
    loading: () => <div className="live-map-loading card">Loading live map…</div>,
  }
);

interface LiveMapClientProps {
  cityId: string;
  citySlug: string;
  cityName: string;
  initialCenter: { lat: number; lng: number };
  initialStatic: LiveMapStaticPayload;
  pollIntervalMs: number;
}

export function LiveMapClient(props: LiveMapClientProps) {
  return <AdminLiveMap {...props} />;
}

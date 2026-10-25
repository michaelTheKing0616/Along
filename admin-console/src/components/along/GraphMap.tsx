'use client';

import { useEffect, useMemo, useRef } from 'react';
import * as maplibregl from 'maplibre-gl';
import { Protocol } from 'pmtiles';
import { loadAlongStyle } from '@/lib/map/style';
import {
  buildLiveMapPaintColors,
  parksToGeoJson,
  routesToGeoJson,
  stagesToGeoJson,
} from '@/lib/map/geojson';
import type { GraphMapPoint, GraphMapRoute } from '@/lib/graph/types';

import 'maplibre-gl/dist/maplibre-gl.css';

interface GraphMapProps {
  center: { lat: number; lng: number };
  parks: GraphMapPoint[];
  stages: GraphMapPoint[];
  routes: GraphMapRoute[];
  pendingStagePositions: Record<string, { lat: number; lng: number }>;
  onStageDrag: (stageId: string, lat: number, lng: number) => void;
  onSelectStage: (stageId: string) => void;
  onSelectPark: (parkId: string) => void;
}

function mergeStagePositions(
  stages: GraphMapPoint[],
  pending: Record<string, { lat: number; lng: number }>
): GraphMapPoint[] {
  return stages.map((stage) => {
    const override = pending[stage.id];
    return override ? { ...stage, lat: override.lat, lng: override.lng } : stage;
  });
}

export function GraphMap({
  center,
  parks,
  stages,
  routes,
  pendingStagePositions,
  onStageDrag,
  onSelectStage,
  onSelectPark,
}: GraphMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const protocolRef = useRef<Protocol | null>(null);
  const dragStageRef = useRef<string | null>(null);

  const displayStages = useMemo(
    () => mergeStagePositions(stages, pendingStagePositions),
    [stages, pendingStagePositions]
  );

  const parksGeo = useMemo(
    () =>
      parksToGeoJson(
        parks.map((p) => ({
          id: p.id,
          name: p.name,
          lat: p.lat,
          lng: p.lng,
          verification_status: p.verification_status,
        }))
      ),
    [parks]
  );

  const stagesGeo = useMemo(
    () =>
      stagesToGeoJson(
        displayStages.map((s) => ({
          id: s.id,
          route_id: s.route_id ?? '',
          name: s.name,
          lat: s.lat,
          lng: s.lng,
          verification_status: s.verification_status,
          is_official_park: s.is_official_park ?? false,
          sequence: 0,
        }))
      ),
    [displayStages]
  );

  const routesGeo = useMemo(
    () =>
      routesToGeoJson(
        routes.map((r) => ({
          id: r.id,
          mode_code: r.mode_code,
          verification_status: r.verification_status,
          coordinates: r.coordinates,
        }))
      ),
    [routes]
  );

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    let cancelled = false;
    const protocol = new Protocol();
    protocolRef.current = protocol;
    maplibregl.addProtocol('pmtiles', protocol.tile);

    void (async () => {
      const style = await loadAlongStyle();
      if (cancelled || !containerRef.current) return;

      const map = new maplibregl.Map({
        container: containerRef.current,
        style: style as maplibregl.StyleSpecification,
        center: [center.lng, center.lat],
        zoom: 11.5,
        attributionControl: {},
      });

      map.addControl(new maplibregl.NavigationControl(), 'top-right');

      map.on('load', () => {
        const colors = buildLiveMapPaintColors();

        map.addSource('graph-routes', { type: 'geojson', data: routesGeo });
        map.addSource('graph-parks', { type: 'geojson', data: parksGeo });
        map.addSource('graph-stages', { type: 'geojson', data: stagesGeo });

        map.addLayer({
          id: 'graph-routes-line',
          type: 'line',
          source: 'graph-routes',
          paint: {
            'line-color': colors.routeFieldVerified,
            'line-width': 2,
            'line-opacity': 0.7,
          },
        });

        map.addLayer({
          id: 'graph-parks-circle',
          type: 'circle',
          source: 'graph-parks',
          paint: {
            'circle-radius': 7,
            'circle-color': colors.park,
            'circle-stroke-width': 2,
            'circle-stroke-color': colors.strokeLight,
          },
        });

        map.addLayer({
          id: 'graph-stages-circle',
          type: 'circle',
          source: 'graph-stages',
          paint: {
            'circle-radius': 6,
            'circle-color': colors.stage,
            'circle-stroke-width': 2,
            'circle-stroke-color': colors.strokeLight,
          },
        });

        map.on('click', 'graph-parks-circle', (event) => {
          const parkId = event.features?.[0]?.id;
          if (typeof parkId === 'string') onSelectPark(parkId);
        });

        map.on('click', 'graph-stages-circle', (event) => {
          const stageId = event.features?.[0]?.id;
          if (typeof stageId === 'string') onSelectStage(stageId);
        });

        map.on('mousedown', 'graph-stages-circle', (event) => {
          const stageId = event.features?.[0]?.id;
          if (typeof stageId !== 'string') return;
          dragStageRef.current = stageId;
          map.getCanvas().style.cursor = 'grabbing';
          event.preventDefault();
        });

        map.on('mousemove', (event) => {
          if (!dragStageRef.current) return;
          onStageDrag(dragStageRef.current, event.lngLat.lat, event.lngLat.lng);
        });

        map.on('mouseup', () => {
          if (dragStageRef.current) {
            dragStageRef.current = null;
            map.getCanvas().style.cursor = '';
          }
        });
      });

      mapRef.current = map;
    })();

    return () => {
      cancelled = true;
      mapRef.current?.remove();
      mapRef.current = null;
      if (protocolRef.current) {
        maplibregl.removeProtocol('pmtiles');
        protocolRef.current = null;
      }
    };
  }, [center.lat, center.lng, onSelectPark, onSelectStage, onStageDrag]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map?.isStyleLoaded()) return;
    const parksSource = map.getSource('graph-parks') as maplibregl.GeoJSONSource | undefined;
    const stagesSource = map.getSource('graph-stages') as maplibregl.GeoJSONSource | undefined;
    const routesSource = map.getSource('graph-routes') as maplibregl.GeoJSONSource | undefined;
    parksSource?.setData(parksGeo);
    stagesSource?.setData(stagesGeo);
    routesSource?.setData(routesGeo);
  }, [parksGeo, stagesGeo, routesGeo]);

  return (
    <div
      ref={containerRef}
      data-testid="graph-map"
      style={{ width: '100%', height: '420px', borderRadius: 'var(--radius-md)' }}
    />
  );
}

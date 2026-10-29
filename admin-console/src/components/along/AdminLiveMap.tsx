"use client";
import type * as GeoJSON from "geojson";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import * as maplibregl from "maplibre-gl";
import { Protocol } from "pmtiles";
import { createClient } from "@/lib/supabase/client";
import {
  applyLiveMapFilters,
  DEFAULT_LAYER_VISIBILITY,
  type RouteFilterState,
} from "@/lib/map/filters";
import {
  activeTripsToGeoJson,
  buildLiveMapPaintColors,
  coverageGapsToGeoJson,
  parksToGeoJson,
  presenceStatusColor,
  presenceToGeoJson,
  routesToGeoJson,
  sosToGeoJson,
  stagesToGeoJson,
} from "@/lib/map/geojson";
import { loadAlongStyle } from "@/lib/map/style";
import type {
  LiveMapActiveTrip,
  LiveMapLayerId,
  LiveMapLayerVisibility,
  LiveMapPresenceVehicle,
  LiveMapSelection,
  LiveMapStaticPayload,
} from "@/lib/map/types";
import { parseActiveTripsMap, parsePresenceVehicles } from "@/lib/map/parse";
import { LiveMapSidePanel } from "./LiveMapSidePanel";

import "maplibre-gl/dist/maplibre-gl.css";
import { configureMapWorker } from "@/lib/map/worker";

const SOURCE_IDS = {
  routes: "along-live-routes",
  parks: "along-live-parks",
  stages: "along-live-stages",
  presence: "along-live-presence",
  trips: "along-live-trips",
  sos: "along-live-sos",
  coverageGaps: "along-live-coverage-gaps",
} as const;

const LAYER_OPTIONS: { id: LiveMapLayerId; label: string }[] = [
  { id: "routes", label: "Routes" },
  { id: "parks", label: "Parks" },
  { id: "stages", label: "Stages" },
  { id: "presence", label: "Live presence" },
  { id: "trips", label: "Active trips" },
  { id: "sos", label: "Open SOS" },
  { id: "coverageGaps", label: "Coverage gaps" },
];

const LAYER_SWATCH: Record<
  LiveMapLayerId,
  keyof ReturnType<typeof buildLiveMapPaintColors>
> = {
  routes: "routeFieldVerified",
  parks: "park",
  stages: "stage",
  presence: "presenceRoamingAvailable",
  trips: "tripLink",
  sos: "sosFill",
  coverageGaps: "coverageGap",
};

interface AdminLiveMapProps {
  citySlug: string;
  cityId: string;
  cityName: string;
  initialStatic: LiveMapStaticPayload;
  initialCenter: { lat: number; lng: number };
  pollIntervalMs: number;
}

function ensureGeoJsonSource(map: maplibregl.Map, sourceId: string) {
  if (!map.getSource(sourceId)) {
    map.addSource(sourceId, {
      type: "geojson",
      data: { type: "FeatureCollection", features: [] },
    });
  }
}

function setGeoJson(
  map: maplibregl.Map,
  sourceId: string,
  data: GeoJSON.FeatureCollection,
) {
  const source = map.getSource(sourceId) as
    maplibregl.GeoJSONSource | undefined;
  source?.setData(data);
}

export function AdminLiveMap({
  citySlug,
  cityId,
  cityName,
  initialStatic,
  initialCenter,
  pollIntervalMs,
}: AdminLiveMapProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const protocolRef = useRef<Protocol | null>(null);

  const [mapReady, setMapReady] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [visibility, setVisibility] = useState<LiveMapLayerVisibility>(
    DEFAULT_LAYER_VISIBILITY,
  );
  const [routeFilters, setRouteFilters] = useState<RouteFilterState>({
    showVerified: true,
    showCandidate: true,
  });
  const [presence, setPresence] = useState<LiveMapPresenceVehicle[]>([]);
  const [trips, setTrips] = useState<LiveMapActiveTrip[]>([]);
  const [selection, setSelection] = useState<LiveMapSelection>(null);
  const [sosPulse, setSosPulse] = useState(0);
  const [palette, setPalette] = useState<ReturnType<
    typeof buildLiveMapPaintColors
  > | null>(null);
  useEffect(() => setPalette(buildLiveMapPaintColors()), []);
  const presenceCounts = useMemo(() => {
    const counts = { at_park: 0, roaming_available: 0, roaming_full: 0 };
    for (const vehicle of presence) {
      const status = (vehicle as { status?: string }).status;
      if (status && status in counts)
        counts[status as keyof typeof counts] += 1;
    }
    return counts;
  }, [presence]);

  const filtered = useMemo(
    () =>
      applyLiveMapFilters({
        ...initialStatic,
        presence,
        trips,
        visibility,
        routeFilters,
      }),
    [initialStatic, presence, trips, visibility, routeFilters],
  );

  const refreshLive = useCallback(async () => {
    const supabase = createClient();
    const [
      { data: presenceData, error: presenceError },
      { data: tripsData, error: tripsError },
    ] = await Promise.all([
      supabase.rpc("admin_presence_snapshot", { p_city_id: cityId }),
      supabase.rpc("admin_active_trips_map", { p_city_id: cityId }),
    ]);

    if (!presenceError && presenceData) {
      setPresence(parsePresenceVehicles(presenceData));
    }
    if (!tripsError && tripsData) {
      setTrips(parseActiveTripsMap(tripsData));
    }
  }, [cityId]);

  useEffect(() => {
    void refreshLive();
    const timer = window.setInterval(() => void refreshLive(), pollIntervalMs);
    return () => window.clearInterval(timer);
  }, [pollIntervalMs, refreshLive]);

  useEffect(() => {
    const timer = window.setInterval(
      () => setSosPulse((value) => (value + 1) % 2),
      800,
    );
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;

    let cancelled = false;
    const protocol = new Protocol();
    protocolRef.current = protocol;
    maplibregl.addProtocol("pmtiles", protocol.tile);

    void (async () => {
      try {
        const style = await loadAlongStyle();
        if (cancelled || !containerRef.current) return;

        configureMapWorker();
        const map = new maplibregl.Map({
          container: containerRef.current,
          style: style as maplibregl.StyleSpecification,
          center: [initialCenter.lng, initialCenter.lat],
          zoom: 12,
          attributionControl: {},
        });

        map.addControl(new maplibregl.NavigationControl(), "top-right");

        map.on("load", () => {
          const colors = buildLiveMapPaintColors();

          ensureGeoJsonSource(map, SOURCE_IDS.routes);
          ensureGeoJsonSource(map, SOURCE_IDS.parks);
          ensureGeoJsonSource(map, SOURCE_IDS.stages);
          ensureGeoJsonSource(map, SOURCE_IDS.presence);
          ensureGeoJsonSource(map, SOURCE_IDS.trips);
          ensureGeoJsonSource(map, SOURCE_IDS.sos);
          ensureGeoJsonSource(map, SOURCE_IDS.coverageGaps);

          map.addLayer({
            id: "along-live-routes-line",
            type: "line",
            source: SOURCE_IDS.routes,
            layout: { visibility: "visible" },
            paint: {
              "line-color": [
                "match",
                ["get", "verification_status"],
                "field_verified",
                colors.routeFieldVerified,
                "crowd_verified",
                colors.routeCrowdVerified,
                colors.routeCandidate,
              ],
              "line-width": 3,
              "line-opacity": 0.85,
            },
          });

          map.addLayer({
            id: "along-live-coverage-heat",
            type: "circle",
            source: SOURCE_IDS.coverageGaps,
            paint: {
              "circle-radius": ["get", "heat_radius"],
              "circle-color": colors.coverageGap,
              "circle-opacity": ["get", "heat_opacity"],
            },
          });

          map.addLayer({
            id: "along-live-parks-circle",
            type: "circle",
            source: SOURCE_IDS.parks,
            paint: {
              "circle-radius": 7,
              "circle-color": colors.park,
              "circle-stroke-width": 2,
              "circle-stroke-color": colors.strokeLight,
            },
          });

          map.addLayer({
            id: "along-live-stages-circle",
            type: "circle",
            source: SOURCE_IDS.stages,
            paint: {
              "circle-radius": 5,
              "circle-color": colors.stage,
              "circle-stroke-width": 1,
              "circle-stroke-color": colors.strokeLight,
            },
          });

          map.addLayer({
            id: "along-live-trips-line",
            type: "line",
            source: SOURCE_IDS.trips,
            filter: ["==", ["get", "kind"], "trip_link"],
            paint: {
              "line-color": colors.tripLink,
              "line-width": 2,
              "line-dasharray": [2, 2],
            },
          });

          map.addLayer({
            id: "along-live-trips-rider",
            type: "circle",
            source: SOURCE_IDS.trips,
            filter: ["==", ["get", "kind"], "trip_rider"],
            paint: {
              "circle-radius": 6,
              "circle-color": colors.tripRider,
            },
          });

          map.addLayer({
            id: "along-live-trips-driver",
            type: "circle",
            source: SOURCE_IDS.trips,
            filter: ["==", ["get", "kind"], "trip_driver"],
            paint: {
              "circle-radius": 6,
              "circle-color": colors.tripDriver,
            },
          });

          map.addLayer({
            id: "along-live-presence-circle",
            type: "circle",
            source: SOURCE_IDS.presence,
            paint: {
              "circle-radius": 8,
              "circle-color": [
                "match",
                ["get", "status"],
                "at_park",
                colors.presenceAtPark,
                "roaming_available",
                colors.presenceRoamingAvailable,
                "roaming_full",
                colors.presenceRoamingFull,
                colors.presenceDefault,
              ],
              "circle-stroke-width": 2,
              "circle-stroke-color": colors.strokeLight,
            },
          });

          map.addLayer({
            id: "along-live-sos-circle",
            type: "circle",
            source: SOURCE_IDS.sos,
            paint: {
              "circle-radius": sosPulse ? 14 : 10,
              "circle-color": colors.sosFill,
              "circle-opacity": sosPulse ? 0.95 : 0.55,
              "circle-stroke-width": 2,
              "circle-stroke-color": colors.sosStroke,
            },
          });

          map.on("click", "along-live-presence-circle", (event) => {
            const feature = event.features?.[0];
            const driverId = feature?.properties?.driver_id;
            if (typeof driverId === "string") {
              setSelection({ kind: "presence", driverId });
            }
          });

          map.on("click", "along-live-trips-line", (event) => {
            const feature = event.features?.[0];
            const tripId = feature?.properties?.trip_id;
            if (typeof tripId === "string") {
              setSelection({ kind: "trip", tripId });
            }
          });

          map.on("click", "along-live-sos-circle", (event) => {
            const feature = event.features?.[0];
            const sosId = feature?.properties?.sos_id;
            if (typeof sosId === "string") {
              setSelection({ kind: "sos", sosId });
            }
          });

          map.on("click", "along-live-parks-circle", (event) => {
            const feature = event.features?.[0];
            const parkId = feature?.id;
            if (typeof parkId === "string") {
              setSelection({ kind: "park", parkId });
            }
          });

          map.on("click", "along-live-stages-circle", (event) => {
            const feature = event.features?.[0];
            const stageId = feature?.id;
            if (typeof stageId === "string") {
              setSelection({ kind: "stage", stageId });
            }
          });

          setMapReady(true);
        });

        mapRef.current = map;
      } catch (error) {
        if (!cancelled) {
          setLoadError(
            error instanceof Error ? error.message : "Map failed to load",
          );
        }
      }
    })();

    return () => {
      cancelled = true;
      mapRef.current?.remove();
      mapRef.current = null;
      if (protocolRef.current) {
        maplibregl.removeProtocol("pmtiles");
        protocolRef.current = null;
      }
    };
  }, [initialCenter.lat, initialCenter.lng]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !mapReady) return;

    setGeoJson(map, SOURCE_IDS.routes, routesToGeoJson(filtered.routes));
    setGeoJson(map, SOURCE_IDS.parks, parksToGeoJson(filtered.parks));
    setGeoJson(map, SOURCE_IDS.stages, stagesToGeoJson(filtered.stages));
    setGeoJson(map, SOURCE_IDS.presence, presenceToGeoJson(filtered.presence));
    setGeoJson(map, SOURCE_IDS.trips, activeTripsToGeoJson(filtered.trips));
    setGeoJson(map, SOURCE_IDS.sos, sosToGeoJson(filtered.sos));
    setGeoJson(
      map,
      SOURCE_IDS.coverageGaps,
      coverageGapsToGeoJson(filtered.coverageGaps),
    );

    const layerVisibility = (layerId: string, visible: boolean) => {
      if (map.getLayer(layerId)) {
        map.setLayoutProperty(
          layerId,
          "visibility",
          visible ? "visible" : "none",
        );
      }
    };

    layerVisibility("along-live-routes-line", visibility.routes);
    layerVisibility("along-live-parks-circle", visibility.parks);
    layerVisibility("along-live-stages-circle", visibility.stages);
    layerVisibility("along-live-presence-circle", visibility.presence);
    layerVisibility("along-live-trips-line", visibility.trips);
    layerVisibility("along-live-trips-rider", visibility.trips);
    layerVisibility("along-live-trips-driver", visibility.trips);
    layerVisibility("along-live-sos-circle", visibility.sos);
    layerVisibility("along-live-coverage-heat", visibility.coverageGaps);
  }, [filtered, mapReady, visibility]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map || !mapReady || !map.getLayer("along-live-sos-circle")) return;
    map.setPaintProperty(
      "along-live-sos-circle",
      "circle-radius",
      sosPulse ? 14 : 10,
    );
    map.setPaintProperty(
      "along-live-sos-circle",
      "circle-opacity",
      sosPulse ? 0.95 : 0.55,
    );
  }, [mapReady, sosPulse]);

  function toggleLayer(layerId: LiveMapLayerId) {
    setVisibility((current) => ({ ...current, [layerId]: !current[layerId] }));
  }

  return (
    <div className="live-map-shell">
      <aside
        className="live-map-controls card"
        aria-label={`Map layers for ${cityName}`}
      >
        <h2 className="live-map-controls-title">Layers</h2>
        <ul className="live-map-layer-list">
          {LAYER_OPTIONS.map(({ id, label }) => (
            <li key={id}>
              <label className="live-map-layer-toggle">
                <input
                  type="checkbox"
                  checked={visibility[id]}
                  onChange={() => toggleLayer(id)}
                />
                <span className="live-map-label">{label}</span>
                {palette ? (
                  <span
                    className={`live-map-swatch${id === "routes" || id === "trips" ? " live-map-swatch-line" : ""}`}
                    style={{ background: palette[LAYER_SWATCH[id]] }}
                    aria-hidden="true"
                  />
                ) : null}
              </label>
            </li>
          ))}
        </ul>
        {palette && visibility.presence ? (
          <div className="live-map-legend" aria-label="Vehicle status">
            <h3 className="live-map-controls-title">Vehicles</h3>
            <ul>
              <li>
                <span
                  className="live-map-swatch"
                  style={{ background: palette.presenceAtPark }}
                  aria-hidden="true"
                />
                At a park <span className="num">{presenceCounts.at_park}</span>
              </li>
              <li>
                <span
                  className="live-map-swatch"
                  style={{ background: palette.presenceRoamingAvailable }}
                  aria-hidden="true"
                />
                Roaming, seats free{" "}
                <span className="num">{presenceCounts.roaming_available}</span>
              </li>
              <li>
                <span
                  className="live-map-swatch"
                  style={{ background: palette.presenceRoamingFull }}
                  aria-hidden="true"
                />
                Roaming, full{" "}
                <span className="num">{presenceCounts.roaming_full}</span>
              </li>
            </ul>
          </div>
        ) : null}
        <fieldset className="live-map-route-filters">
          <legend>Show routes that are</legend>
          <label>
            <input
              type="checkbox"
              checked={routeFilters.showVerified}
              onChange={(event) =>
                setRouteFilters((current) => ({
                  ...current,
                  showVerified: event.target.checked,
                }))
              }
            />
            Verified (crowd or field)
          </label>
          <label>
            <input
              type="checkbox"
              checked={routeFilters.showCandidate}
              onChange={(event) =>
                setRouteFilters((current) => ({
                  ...current,
                  showCandidate: event.target.checked,
                }))
              }
            />
            Candidate (not yet verified)
          </label>
        </fieldset>
        <p className="live-map-meta">
          Positions refresh every {pollIntervalMs / 1000} s.
        </p>
        {loadError ? (
          <p className="live-map-error" role="alert">
            Live data could not be loaded ({loadError}). Retrying automatically.
          </p>
        ) : null}
      </aside>

      <div className="live-map-main">
        <div
          ref={containerRef}
          className="live-map-canvas"
          data-testid="live-map-canvas"
        />
        <LiveMapSidePanel
          citySlug={citySlug}
          selection={selection}
          staticData={initialStatic}
          presence={presence}
          trips={trips}
          onClose={() => setSelection(null)}
        />
      </div>
    </div>
  );
}

export { presenceStatusColor };

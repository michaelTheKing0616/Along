import * as maplibregl from "maplibre-gl";

// See scripts/copy-map-worker.mjs: the worker is served from /public.
export const MAP_WORKER_URL = "/maplibre-gl-worker.mjs";

let configured = false;
export function configureMapWorker(): void {
  if (configured || typeof window === "undefined") return;
  maplibregl.setWorkerUrl(MAP_WORKER_URL);
  configured = true;
}

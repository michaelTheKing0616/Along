// MapLibre resolves its worker relative to the bundle chunk URL, which Next.js
// does not emit. Serve the worker from /public and point setWorkerUrl at it.
import { copyFileSync, mkdirSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";

const require = createRequire(import.meta.url);
const dist = join(dirname(require.resolve("maplibre-gl/package.json")), "dist");
mkdirSync(new URL("../public", import.meta.url), { recursive: true });
copyFileSync(
  join(dist, "maplibre-gl-worker.mjs"),
  new URL("../public/maplibre-gl-worker.mjs", import.meta.url),
);

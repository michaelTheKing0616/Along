/** Self-hosted PMTiles / along-light style origin (ADR-0006, ADR-0013). */
export function getTilesBaseUrl(): string {
  return (
    process.env.NEXT_PUBLIC_TILES_BASE_URL?.replace(/\/$/, '') ??
    'https://tiles.dev.along.ng'
  );
}

export function getPmtilesUrl(): string {
  const base = getTilesBaseUrl();
  return `${base}/nigeria.pmtiles`;
}

export function getStyleUrl(): string {
  return `${getTilesBaseUrl()}/styles/along-light.json`;
}

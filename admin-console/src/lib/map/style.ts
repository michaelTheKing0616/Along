import { getPmtilesUrl, getTilesBaseUrl } from './config';

/** Resolve along-light placeholders for MapLibre GL JS (mirrors Flutter AlongStyleLoader). */
export function resolveAlongStyleJson(rawStyleJson: string): string {
  const tilesBase = getTilesBaseUrl();
  const pmtilesUrl = getPmtilesUrl();
  const pmtilesRef = `pmtiles://${pmtilesUrl}`;
  const sprite = `${tilesBase}/sprites/along-light`;
  const glyphs = `${tilesBase}/glyphs/{fontstack}/{range}.pbf`;

  return rawStyleJson
    .replaceAll('{{PMTILES_URL}}', pmtilesUrl)
    .replaceAll('{{SPRITE_URL}}', sprite)
    .replaceAll('{{GLYPHS_URL}}', glyphs)
    .replaceAll('"url": "pmtiles://{{PMTILES_URL}}"', `"url": "${pmtilesRef}"`);
}

export async function loadAlongStyle(): Promise<Record<string, unknown>> {
  const response = await fetch(getTilesBaseUrl() + '/styles/along-light.json');
  if (!response.ok) {
    throw new Error(`Failed to load map style (${response.status})`);
  }
  const raw = await response.text();
  return JSON.parse(resolveAlongStyleJson(raw)) as Record<string, unknown>;
}

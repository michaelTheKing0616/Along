/** Haversine distance in metres between WGS84 [lng, lat] points. */
export function haversineM(a: [number, number], b: [number, number]): number {
  const earthRadiusM = 6_371_000;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b[1] - a[1]);
  const dLng = toRad(b[0] - a[0]);
  const lat1 = toRad(a[1]);
  const lat2 = toRad(b[1]);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * earthRadiusM * Math.asin(Math.sqrt(h));
}

function resampleLine(
  coords: [number, number][],
  targetCount: number,
): [number, number][] {
  if (coords.length <= targetCount) return coords;
  const step = (coords.length - 1) / (targetCount - 1);
  return Array.from({ length: targetCount }, (_, i) => {
    const idx = Math.min(coords.length - 1, Math.round(i * step));
    return coords[idx]!;
  });
}

/**
 * Discrete Fréchet distance (m) between two LineStrings.
 * Coordinates are resampled to a common count for stable comparison.
 */
export function discreteFrechetM(
  lineA: [number, number][],
  lineB: [number, number][],
): number {
  if (lineA.length === 0 || lineB.length === 0) return Infinity;
  const sampleCount = Math.max(lineA.length, lineB.length, 2);
  const a = resampleLine(lineA, sampleCount);
  const b = resampleLine(lineB, sampleCount);

  const ca: number[][] = Array.from({ length: a.length }, () =>
    Array.from({ length: b.length }, () => -1),
  );

  function dist(i: number, j: number): number {
    if (ca[i]![j]! > -1) return ca[i]![j]!;
    const d = haversineM(a[i]!, b[j]!);
    if (i === 0 && j === 0) {
      ca[i]![j] = d;
    } else if (i === 0) {
      ca[i]![j] = Math.max(dist(i, j - 1), d);
    } else if (j === 0) {
      ca[i]![j] = Math.max(dist(i - 1, j), d);
    } else {
      ca[i]![j] = Math.max(
        Math.min(dist(i - 1, j), dist(i - 1, j - 1), dist(i, j - 1)),
        d,
      );
    }
    return ca[i]![j]!;
  }

  return dist(a.length - 1, b.length - 1);
}

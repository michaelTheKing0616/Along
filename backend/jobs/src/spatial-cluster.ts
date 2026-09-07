import { haversineM } from './frechet.js';

export type ClusterPoint = {
  id: string;
  lng: number;
  lat: number;
};

/** Greedy metric clustering — assigns each point a cluster index. */
export function clusterPoints(
  points: ClusterPoint[],
  epsM: number,
): Map<string, number> {
  const assignments = new Map<string, number>();
  const centroids: Array<{ lng: number; lat: number }> = [];
  let nextCluster = 0;

  for (const point of points) {
    let assigned = false;
    for (let clusterId = 0; clusterId < centroids.length; clusterId += 1) {
      const centroid = centroids[clusterId]!;
      if (
        haversineM([point.lng, point.lat], [centroid.lng, centroid.lat]) <= epsM
      ) {
        assignments.set(point.id, clusterId);
        assigned = true;
        break;
      }
    }
    if (!assigned) {
      assignments.set(point.id, nextCluster);
      centroids.push({ lng: point.lng, lat: point.lat });
      nextCluster += 1;
    }
  }

  return assignments;
}

/** In-process TTL cache for Edge Functions (P7-A-01). No new dependencies. */

export type CacheStats = {
  hits: number;
  misses: number;
  hit_ratio: number;
};

type CacheEntry<T> = {
  value: T;
  expiresAt: number;
};

export class TtlCache<T> {
  readonly #store = new Map<string, CacheEntry<T>>();
  #hits = 0;
  #misses = 0;

  constructor(private readonly maxEntries: number) {}

  get(key: string, now = Date.now()): T | undefined {
    const entry = this.#store.get(key);
    if (!entry) {
      this.#misses++;
      return undefined;
    }
    if (entry.expiresAt <= now) {
      this.#store.delete(key);
      this.#misses++;
      return undefined;
    }
    this.#hits++;
    return entry.value;
  }

  set(key: string, value: T, ttlMs: number, now = Date.now()): void {
    if (ttlMs <= 0) return;
    if (this.#store.size >= this.maxEntries && !this.#store.has(key)) {
      const oldestKey = this.#store.keys().next().value;
      if (oldestKey !== undefined) this.#store.delete(oldestKey);
    }
    this.#store.set(key, { value, expiresAt: now + ttlMs });
  }

  stats(): CacheStats {
    const total = this.#hits + this.#misses;
    return {
      hits: this.#hits,
      misses: this.#misses,
      hit_ratio: total === 0 ? 0 : this.#hits / total,
    };
  }

  clear(): void {
    this.#store.clear();
    this.#hits = 0;
    this.#misses = 0;
  }
}

/** Stable hash for plan-trip filter objects (doc 07 §4). */
function sortKeys(value: unknown): unknown {
  if (value === null || typeof value !== 'object') return value;
  if (Array.isArray(value)) return value.map(sortKeys);
  const obj = value as Record<string, unknown>;
  const sorted: Record<string, unknown> = {};
  for (const key of Object.keys(obj).sort()) {
    sorted[key] = sortKeys(obj[key]);
  }
  return sorted;
}

export function filtersHash(filters: unknown): string {
  return JSON.stringify(sortKeys(filters));
}

export type NamedCacheStats = Record<string, CacheStats>;

const planTripCache = new TtlCache<unknown>(256);
const placesSearchCache = new TtlCache<unknown>(512);
const graphBundleCache = new TtlCache<unknown>(32);

export function getPlanTripCache(): TtlCache<unknown> {
  return planTripCache;
}

export function getPlacesSearchCache(): TtlCache<unknown> {
  return placesSearchCache;
}

export function getGraphBundleCache(): TtlCache<unknown> {
  return graphBundleCache;
}

export function allCacheStats(): NamedCacheStats {
  return {
    plan_trip: planTripCache.stats(),
    places_search: placesSearchCache.stats(),
    graph_bundle: graphBundleCache.stats(),
  };
}

/** Test helper — resets module-level caches between Deno tests. */
export function resetEdgeCachesForTests(): void {
  planTripCache.clear();
  placesSearchCache.clear();
  graphBundleCache.clear();
}

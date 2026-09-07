/**
 * Hot OD pairs for plan-trip load (Zaria-Test seed coordinates).
 * Spread origins/destinations to exercise cache miss + hit paths.
 */
export const PLAN_TRIP_OD_PAIRS = [
  { origin: { lat: 11.061, lng: 7.701 }, destination: { lat: 11.068, lng: 7.708 } },
  { origin: { lat: 11.062, lng: 7.702 }, destination: { lat: 11.069, lng: 7.709 } },
  { origin: { lat: 11.063, lng: 7.703 }, destination: { lat: 11.070, lng: 7.710 } },
  { origin: { lat: 11.064, lng: 7.704 }, destination: { lat: 11.071, lng: 7.711 } },
  { origin: { lat: 11.065, lng: 7.705 }, destination: { lat: 11.072, lng: 7.712 } },
  { origin: { lat: 11.066, lng: 7.706 }, destination: { lat: 11.073, lng: 7.713 } },
  { origin: { lat: 11.067, lng: 7.707 }, destination: { lat: 11.074, lng: 7.714 } },
  { origin: { lat: 11.068, lng: 7.708 }, destination: { lat: 11.075, lng: 7.715 } },
];

export function planTripBody(riderJwt, vu, iter) {
  const pair = PLAN_TRIP_OD_PAIRS[(vu + iter) % PLAN_TRIP_OD_PAIRS.length];
  return {
    origin: pair.origin,
    destination: pair.destination,
    filters: { women_only: false, load: { flagged: false } },
    session_id: `00000000-0000-4000-8000-${String(vu).padStart(12, '0')}`,
  };
}

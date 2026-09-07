/**
 * Budget thresholds from docs/blueprint/01_architecture.md §7 and app_config defaults.
 * Values mirror migration config_default() keys — not fetched at runtime so k6 stays dependency-free.
 */
export const THRESHOLDS = {
  presencePingP95Ms: 300,
  setPresenceP95Ms: 300,
  planTripP95Ms: 800,
  ambientFanoutP95Ms: 10_000,
  realtimeMessageP95Ms: 1_000,
  presencePingMinIntervalS: 2,
  presenceFanoutIntervalS: 10,
  realtimeMaxPayloadBytes: 512,
};

/** TS-OPS-02 full-city targets (doc 10 §3 Ops). */
export const FULL_CITY = {
  planTripRps: 200,
  presencePingRps: 1_000,
  duration: '10m',
  tripSubscriberVus: 5_000,
};

/** Scaled local proof defaults when the host cannot sustain FULL_CITY concurrency. */
export const SCALED_LOCAL = {
  planTripRps: 20,
  presencePingRps: 100,
  duration: '2m',
  tripSubscriberVus: 50,
  /** Multiply measured rates by this to extrapolate toward full-city targets. */
  scaleFactor: 10,
};

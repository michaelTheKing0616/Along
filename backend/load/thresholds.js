/**
 * Budget thresholds from docs/blueprint/01_architecture.md §7 and app_config defaults.
 * Values mirror migration config_default() keys — not fetched at runtime so k6 stays dependency-free.
 */
export const THRESHOLDS = {
  presencePingP95Ms: 300,
  setPresenceP95Ms: 300,
  ambientFanoutP95Ms: 10_000,
  realtimeMessageP95Ms: 1_000,
  presencePingMinIntervalS: 2,
  presenceFanoutIntervalS: 10,
  realtimeMaxPayloadBytes: 512,
};

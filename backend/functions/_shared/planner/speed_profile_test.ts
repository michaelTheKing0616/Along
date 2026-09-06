import { assertEquals } from 'jsr:@std/assert@1';
import {
  calibrateInVehicleS,
  dowBucket,
  hourBucket,
} from './speed_profile.ts';

const cfg = {
  baselineSpeedMps: 10,
  speedProfileMinSamples: 8,
};

Deno.test('TS-PLAN-09: speed profile scales in-vehicle time', () => {
  const base = 600;
  const scaled = calibrateInVehicleS(base, [{
    segment_key: '12345:forward',
    median_speed_mps: 5,
    sample_count: 12,
  }], cfg);
  assertEquals(scaled, 1200);
});

Deno.test('speed profile below min samples leaves in-vehicle time unchanged', () => {
  const base = 600;
  const scaled = calibrateInVehicleS(base, [{
    segment_key: '12345:forward',
    median_speed_mps: 5,
    sample_count: 3,
  }], cfg);
  assertEquals(scaled, 600);
});

Deno.test('speed profile faster traffic reduces in-vehicle time', () => {
  const base = 600;
  const scaled = calibrateInVehicleS(base, [{
    segment_key: '12345:forward',
    median_speed_mps: 20,
    sample_count: 10,
  }], cfg);
  assertEquals(scaled, 300);
});

Deno.test('dowBucket: weekday vs weekend', () => {
  assertEquals(dowBucket(new Date('2026-09-06T12:00:00Z'), 'UTC'), 1);
  assertEquals(dowBucket(new Date('2026-09-08T12:00:00Z'), 'UTC'), 0);
});

Deno.test('hourBucket returns local hour', () => {
  assertEquals(hourBucket(new Date('2026-09-08T14:30:00Z'), 'UTC'), 14);
});

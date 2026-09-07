import graphSnapRadiusM from '../../../../shared/contracts/config-schemas/graph.snap_radius_m.json';
import opsLiveMapPollS from '../../../../shared/contracts/config-schemas/ops.live_map_poll_s.json';
import commissionRate from '../../../../shared/contracts/config-schemas/commission.rate.json';
import paymentsDigitalEnabled from '../../../../shared/contracts/config-schemas/payments.digital_enabled.json';

export type ConfigValueSchema = {
  type: 'number' | 'boolean' | 'string' | 'object' | 'array';
  minimum?: number;
  maximum?: number;
  description?: string;
};

const SCHEMAS: Record<string, ConfigValueSchema> = {
  'graph.snap_radius_m': graphSnapRadiusM as ConfigValueSchema,
  'ops.live_map_poll_s': opsLiveMapPollS as ConfigValueSchema,
  'commission.rate': commissionRate as ConfigValueSchema,
  'payments.digital_enabled': paymentsDigitalEnabled as ConfigValueSchema,
};

export function getConfigSchema(key: string): ConfigValueSchema | null {
  return SCHEMAS[key] ?? null;
}

export function parseConfigInput(key: string, raw: string): { ok: true; value: unknown } | { ok: false; error: string } {
  const schema = getConfigSchema(key);
  if (!schema) {
    try {
      return { ok: true, value: JSON.parse(raw) };
    } catch {
      return { ok: false, error: 'Invalid JSON value.' };
    }
  }

  if (schema.type === 'number') {
    const num = Number(raw);
    if (!Number.isFinite(num)) return { ok: false, error: 'Enter a valid number.' };
    if (schema.minimum != null && num < schema.minimum) {
      return { ok: false, error: `Minimum is ${schema.minimum}.` };
    }
    if (schema.maximum != null && num > schema.maximum) {
      return { ok: false, error: `Maximum is ${schema.maximum}.` };
    }
    return { ok: true, value: num };
  }

  if (schema.type === 'boolean') {
    if (raw === 'true') return { ok: true, value: true };
    if (raw === 'false') return { ok: true, value: false };
    return { ok: false, error: 'Select true or false.' };
  }

  if (schema.type === 'string') {
    return { ok: true, value: raw };
  }

  try {
    const parsed = JSON.parse(raw) as unknown;
    if (schema.type === 'object' && (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed))) {
      return { ok: false, error: 'Expected a JSON object.' };
    }
    if (schema.type === 'array' && !Array.isArray(parsed)) {
      return { ok: false, error: 'Expected a JSON array.' };
    }
    return { ok: true, value: parsed };
  } catch {
    return { ok: false, error: 'Invalid JSON value.' };
  }
}

export function formatConfigValue(value: unknown): string {
  if (typeof value === 'string') return value;
  return JSON.stringify(value);
}

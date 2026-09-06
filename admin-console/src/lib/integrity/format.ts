import type { IntegrityFlagRow } from './types';

export function sortFlagsByScore(rows: IntegrityFlagRow[]): IntegrityFlagRow[] {
  return [...rows].sort((a, b) => {
    if (a.status !== b.status) {
      if (a.status === 'open') return -1;
      if (b.status === 'open') return 1;
    }
    return b.score - a.score;
  });
}

export function flagTypeLabel(type: IntegrityFlagRow['flag_type']): string {
  return type.replace(/_/g, ' ');
}

export function evidenceBullets(evidence: Record<string, unknown>): string[] {
  const bullets: string[] = [];

  for (const [key, value] of Object.entries(evidence)) {
    if (value == null) continue;
    if (typeof value === 'object' && !Array.isArray(value)) {
      for (const [subKey, subVal] of Object.entries(value as Record<string, unknown>)) {
        bullets.push(`${key}.${subKey}: ${formatEvidenceValue(subVal)}`);
      }
    } else {
      bullets.push(`${key}: ${formatEvidenceValue(value)}`);
    }
  }

  return bullets.length > 0 ? bullets : ['No structured evidence'];
}

function formatEvidenceValue(value: unknown): string {
  if (typeof value === 'number') return value.toLocaleString();
  if (typeof value === 'boolean') return value ? 'yes' : 'no';
  return String(value);
}

export function scorePct(score: number): string {
  return `${(score * 100).toFixed(1)}%`;
}

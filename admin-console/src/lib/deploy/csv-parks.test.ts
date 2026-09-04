import { describe, expect, it } from 'vitest';
import { diffParksCsv, parseParksCsv } from './csv-parks.js';

describe('parseParksCsv', () => {
  it('parses headered CSV rows', () => {
    const result = parseParksCsv(
      'name,lat,lng,aliases\nTest Park,9.05,7.40,E2E|Park'
    );
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.rows).toHaveLength(1);
      expect(result.rows[0]).toMatchObject({
        name: 'Test Park',
        lat: 9.05,
        lng: 7.4,
        aliases: ['E2E', 'Park'],
      });
    }
  });

  it('returns errors for invalid rows', () => {
    const result = parseParksCsv('Bad Row');
    expect(result.ok).toBe(false);
  });
});

describe('diffParksCsv', () => {
  it('skips existing park names case-insensitively', () => {
    const parsed = parseParksCsv('Nyanya Park,9.01,7.59');
    expect(parsed.ok).toBe(true);
    if (!parsed.ok) return;

    const diff = diffParksCsv(parsed.rows, ['nyanya park']);
    expect(diff[0]?.action).toBe('skip');
  });

  it('marks new parks as create', () => {
    const parsed = parseParksCsv('Brand New Park,9.01,7.59');
    expect(parsed.ok).toBe(true);
    if (!parsed.ok) return;

    const diff = diffParksCsv(parsed.rows, []);
    expect(diff[0]?.action).toBe('create');
  });
});

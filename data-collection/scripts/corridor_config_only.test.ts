import { describe, expect, it } from 'vitest';
import {
  assertFixtureIsDataOnly,
  loadFixtureDir,
} from './import_corridor.ts';
import { buildCorridorBundle, CORRIDOR_DATA_ONLY_EXTENSIONS } from '../../shared/contracts/corridor-import.ts';

describe('corridor_zaria_beta fixture', () => {
  const fixtureDir = 'fixtures/corridor_zaria_beta';

  it('contains only data/config file types', () => {
    expect(() => assertFixtureIsDataOnly(fixtureDir)).not.toThrow();
    for (const ext of CORRIDOR_DATA_ONLY_EXTENSIONS) {
      expect(['.csv', '.json', '.sql', '.md']).toContain(ext);
    }
  });

  it('loads manifest and parses a complete corridor bundle without code changes', () => {
    const { manifest, bundle } = loadFixtureDir(fixtureDir);
    expect(manifest.target_city_slug).toBe('zaria-test');
    expect(manifest.corridor.slug).toBe('test-corridor-beta');

    const built = buildCorridorBundle(bundle);
    expect(built.ok).toBe(true);
    if (!built.ok) return;

    expect(built.bundle.kind).toBe('corridor');
    expect((built.bundle.parks as unknown[]).length).toBeGreaterThan(0);
    expect((built.bundle.routes as unknown[]).length).toBeGreaterThan(0);
    expect((built.bundle.stages as unknown[]).length).toBeGreaterThan(0);
    expect((built.bundle.leg_fares as unknown[]).length).toBeGreaterThan(0);
  });

  it('fails when fixture directory would require application code (non-data files)', () => {
    expect(() => assertFixtureIsDataOnly('scripts')).toThrow(/non-data file/);
  });
});

import { describe, expect, it } from 'vitest';
import {
  buildCorridorBundle,
  parseCorridorManifest,
  routeDisplayName,
} from '@along/contracts';

const FIXTURE_MANIFEST = {
  corridor: { name: 'Test Corridor Beta', slug: 'test-corridor-beta' },
  parks: `name,aliases,lat,lng,modes
Fictional Park North,,11.070,7.690,car|keke
Fictional Park South,,11.075,7.695,car|keke`,
  routes: `origin_park,destination_park,mode,name
Fictional Park North,Fictional Park South,car,Beta Car Route
Fictional Park North,Fictional Park South,keke,Beta Keke Route`,
  stages: `route_name,sequence,stage_name,lat,lng,is_official_park
Beta Car Route,1,Fictional Park North,11.070,7.690,true
Beta Car Route,2,Beta Junction One,11.071,7.691,false
Beta Car Route,3,Beta Junction Two,11.073,7.693,false
Beta Car Route,4,Fictional Park South,11.075,7.695,true
Beta Keke Route,1,Fictional Park North,11.070,7.690,true
Beta Keke Route,2,Beta Junction One,11.071,7.691,false
Beta Keke Route,3,Beta Junction Two,11.073,7.693,false
Beta Keke Route,4,Fictional Park South,11.075,7.695,true`,
  leg_fares: `route_name,from_seq,to_seq,fare
Beta Car Route,1,2,100
Beta Car Route,2,3,100
Beta Car Route,3,4,100
Beta Keke Route,1,2,60
Beta Keke Route,2,3,60
Beta Keke Route,3,4,60`,
  through_fares: `route_name,from_seq,to_seq,fare
Beta Car Route,1,4,280`,
};

describe('parseCorridorManifest', () => {
  it('parses doc 13 corridor CSV bundle', () => {
    const result = parseCorridorManifest(FIXTURE_MANIFEST);
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.parks).toHaveLength(2);
    expect(result.routes).toHaveLength(2);
    expect(result.stages).toHaveLength(8);
    expect(result.leg_fares).toHaveLength(6);
    expect(result.through_fares).toHaveLength(1);
  });

  it('builds RPC bundle with structured arrays', () => {
    const built = buildCorridorBundle(FIXTURE_MANIFEST);
    expect(built.ok).toBe(true);
    if (!built.ok) return;
    expect(built.bundle.kind).toBe('corridor');
    expect(Array.isArray(built.bundle.parks)).toBe(true);
    expect((built.bundle.routes as Array<{ name: string }>)[0]?.name).toBe('Beta Car Route');
  });

  it('derives route display names when name column empty', () => {
    const row = {
      line: 1,
      origin_park: 'A',
      destination_park: 'B',
      mode: 'car',
      name: '',
    };
    expect(routeDisplayName(row)).toBe('A → B (car)');
  });
});

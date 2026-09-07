#!/usr/bin/env -S deno run --allow-read --allow-write --allow-env --allow-run
const ROOT = new URL('..', import.meta.url).pathname.replace(/\/$/, '');

type Fixture = {
  city_id: string;
  city_slug: string;
  geohash5: string;
  drivers: Array<{ id: string; jwt: string }>;
  riders: Array<{ id: string; jwt: string }>;
  trips: Array<{ id: string; rider_jwt: string; driver_jwt: string }>;
};

function b64url(input: string | Uint8Array): string {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let binary = '';
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

async function signJwt(
  payload: Record<string, unknown>,
  secret: string,
): Promise<string> {
  const header = { alg: 'HS256', typ: 'JWT' };
  const body = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(payload))}`;
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(body));
  return `${body}.${b64url(new Uint8Array(sig))}`;
}

async function mintUserToken(userId: string, secret: string): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  return signJwt(
    {
      iss: 'supabase-demo',
      sub: userId,
      aud: 'authenticated',
      role: 'authenticated',
      iat: now,
      exp: now + 3600,
    },
    secret,
  );
}

function driverId(i: number): string {
  return `0e100000-0000-4000-8000-${i.toString(16).padStart(12, '0')}`;
}

function riderId(i: number): string {
  return `0e200000-0000-4000-8000-${i.toString(16).padStart(12, '0')}`;
}

async function main() {
  const jwtSecret = Deno.env.get('JWT_SECRET');
  if (!jwtSecret) {
    console.error('JWT_SECRET env required (from `supabase status --output json`)');
    Deno.exit(1);
  }

  const dbUrl = Deno.env.get('DB_URL') ??
    'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
  const driverCount = Number(Deno.env.get('LOAD_DRIVER_COUNT') ?? '10');
  const riderCount = Number(Deno.env.get('LOAD_RIDER_COUNT') ?? '5');
  const tripLimit = Number(Deno.env.get('LOAD_TRIP_LIMIT') ?? '50');

  const proc = new Deno.Command('psql', {
    args: [dbUrl, '-At', '-c', `
      select coalesce(
        (select geohash5 from presence_fanout_targets() limit 1),
        's6hg7'
      );
      select t.id::text
      from trips t
      join journeys j on j.id = t.journey_id
      where t.status in ('accepted', 'boarded', 'in_transit')
        and j.city_id = '0a000000-0000-4000-8000-000000000001'
      order by t.created_at desc
      limit ${tripLimit};
    `],
    stdout: 'piped',
    stderr: 'inherit',
  });
  const { code, stdout } = await proc.output();
  if (code !== 0) Deno.exit(code);
  const lines = new TextDecoder().decode(stdout).trim().split('\n').filter(Boolean);
  const geohash5 = lines[0] || 's6hg5';
  const tripIds = lines.slice(1);

  const drivers = [];
  for (let i = 1; i <= driverCount; i++) {
    const id = driverId(i);
    drivers.push({ id, jwt: await mintUserToken(id, jwtSecret) });
  }

  const riders = [];
  for (let i = 1; i <= riderCount; i++) {
    const id = riderId(i);
    riders.push({ id, jwt: await mintUserToken(id, jwtSecret) });
  }

  const trips = [];
  if (tripIds.length > 0) {
    const tripMetaProc = new Deno.Command('psql', {
      args: [dbUrl, '-At', '-F', ',', '-c', `
        select id::text, rider_id::text, driver_id::text
        from trips
        where id = any(array[${tripIds.map((id) => `'${id}'`).join(',')}]::uuid[])
        order by created_at desc;
      `],
      stdout: 'piped',
      stderr: 'inherit',
    });
    const tripMetaOut = await tripMetaProc.output();
    if (tripMetaOut.code !== 0) Deno.exit(tripMetaOut.code);
    const tripLines = new TextDecoder().decode(tripMetaOut.stdout).trim().split('\n').filter(Boolean);
    const driverJwtById = new Map(drivers.map((d) => [d.id, d.jwt]));
    const riderJwtById = new Map(riders.map((r) => [r.id, r.jwt]));
    for (const line of tripLines) {
      const [id, riderIdVal, driverIdVal] = line.split(',');
      const riderJwt = riderJwtById.get(riderIdVal);
      const driverJwt = driverJwtById.get(driverIdVal);
      if (!id || !riderJwt || !driverJwt) continue;
      trips.push({ id, rider_jwt: riderJwt, driver_jwt: driverJwt });
    }
  }

  const fixture: Fixture = {
    city_id: '0a000000-0000-4000-8000-000000000001',
    city_slug: 'zaria-test',
    geohash5,
    drivers,
    riders,
    trips,
  };

  const outPath = `${ROOT}/.tokens.json`;
  await Deno.writeTextFile(outPath, JSON.stringify(fixture, null, 2));
  console.error(
    `Wrote ${drivers.length} driver + ${riders.length} rider tokens (${trips.length} trips) → ${outPath}`,
  );
}

main();

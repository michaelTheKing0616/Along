import { assertEquals, assertExists } from 'jsr:@std/assert@1';
import type { SupabaseClient } from '@supabase/supabase-js';
import {
  handleParseItinerary,
  parseItineraryText,
  type ParseItineraryRequest,
} from './handler.ts';

const CITY_ID = 'b1000000-0000-4000-8000-000000000001';

const baseRequest: ParseItineraryRequest = {
  text: 'drop the kids at school then work then market',
  city_id: CITY_ID,
};

function createMockUserClient(): SupabaseClient {
  return {
    auth: {
      getUser: () =>
        Promise.resolve({ data: { user: { id: '0a200000-0000-4000-8000-000000000001' } }, error: null }),
    },
  } as unknown as SupabaseClient;
}

function createWriteSpyServiceClient(): SupabaseClient & { writeCount: number } {
  let writeCount = 0;
  const client = {
    writeCount: 0,
    from: (table: string) => {
      writeCount += 1;
      throw new Error(`unexpected write to ${table}`);
    },
    rpc: (name: string) => {
      if (
        name.startsWith('insert_') ||
        name.startsWith('create_') ||
        name.startsWith('update_') ||
        name.startsWith('store_')
      ) {
        writeCount += 1;
        throw new Error(`unexpected rpc write: ${name}`);
      }
      return Promise.resolve({ data: null, error: null });
    },
  } as unknown as SupabaseClient & { writeCount: number };

  Object.defineProperty(client, 'writeCount', {
    get: () => writeCount,
  });

  return client;
}

Deno.test('parse-itinerary: splits NL text into ordered stops', () => {
  const stops = parseItineraryText('school then work then market');
  assertEquals(stops.length, 3);
  assertEquals(stops[0].sequence, 1);
  assertEquals(stops[0].destination_description, 'school');
  assertEquals(stops[2].destination_description, 'market');
});

Deno.test('parse-itinerary: parses JSON-ish stop array', () => {
  const stops = parseItineraryText('[{"destination_description":"school"},{"destination_description":"work"}]');
  assertEquals(stops.length, 2);
  assertEquals(stops[1].destination_description, 'work');
});

Deno.test('parse-itinerary: returns proposal with needs_confirmation', async () => {
  const res = await handleParseItinerary(baseRequest, 'Bearer test-token', {
    user: createMockUserClient(),
  });

  assertEquals(res.status, 200);
  const body = await res.json();
  assertEquals(body.data.needs_confirmation, true);
  assertEquals(body.data.proposal.length, 3);
  assertEquals(body.data.proposal[0].resolved, null);
  assertExists(body.meta.request_id);
});

Deno.test('parse-itinerary: never inserts or updates any tables', async () => {
  const spy = createWriteSpyServiceClient();

  const res = await handleParseItinerary(baseRequest, 'Bearer test-token', {
    user: createMockUserClient(),
    service: spy,
  });

  assertEquals(res.status, 200);
  assertEquals(spy.writeCount, 0);
});

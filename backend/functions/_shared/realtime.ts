/** Supabase Realtime Broadcast REST client (service role). */

export type RealtimeBroadcastClient = {
  send(params: {
    topic: string;
    event: string;
    payload: unknown;
    private?: boolean;
  }): Promise<void>;
};

export function createRealtimeBroadcastClient(
  fetchFn: typeof fetch = fetch,
): RealtimeBroadcastClient {
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) {
    throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  }

  const endpoint = `${url.replace(/\/$/, '')}/realtime/v1/api/broadcast`;

  return {
    async send({ topic, event, payload, private: isPrivate = true }) {
      const res = await fetchFn(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          apikey: key,
          Authorization: `Bearer ${key}`,
        },
        body: JSON.stringify({
          messages: [{ topic, event, payload, private: isPrivate }],
        }),
      });

      if (!res.ok) {
        const text = await res.text();
        throw new Error(`Realtime broadcast failed (${res.status}): ${text}`);
      }
    },
  };
}

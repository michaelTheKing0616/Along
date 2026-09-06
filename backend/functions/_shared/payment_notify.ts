import { createFcmClient, type FcmClient } from './fcm.ts';
import { createRealtimeBroadcastClient, type RealtimeBroadcastClient } from './realtime.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export type PaymentNotifyDeps = {
  service: SupabaseClient;
  realtime: RealtimeBroadcastClient;
  fcm: FcmClient;
};

export async function notifyPaymentReceived(
  deps: PaymentNotifyDeps,
  paymentId: string,
): Promise<{ broadcast: boolean; pushes: number }> {
  const { data: payment, error } = await deps.service
    .from('payments')
    .select('id, driver_id, amount, driver_amount, commission_amount, currency, source, trip_id')
    .eq('id', paymentId)
    .single();

  if (error || !payment) {
    throw new Error('payment not found for notify');
  }

  const p = payment as {
    id: string;
    driver_id: string;
    amount: number;
    driver_amount: number;
    commission_amount: number;
    currency: string;
    source: string;
    trip_id: string | null;
  };

  await deps.realtime.send({
    topic: `driver:${p.driver_id}`,
    event: 'payment_received',
    payload: {
      type: 'payment_received',
      payment_id: p.id,
      amount: p.amount,
      driver_amount: p.driver_amount,
      commission_amount: p.commission_amount,
      currency: p.currency,
      source: p.source,
      trip_id: p.trip_id,
    },
    private: true,
  });

  const { data: tokens, error: tokenError } = await deps.service
    .from('device_tokens')
    .select('token')
    .eq('profile_id', p.driver_id)
    .eq('app', 'driver');

  if (tokenError) {
    throw new Error(tokenError.message);
  }

  let pushes = 0;
  for (const row of tokens ?? []) {
    await deps.fcm.sendDataMessage({
      token: (row as { token: string }).token,
      data: {
        type: 'payment_received',
        payment_id: p.id,
      },
      ttlSeconds: 120,
      collapseKey: `payment_${p.id}`,
      priority: 'high',
    });
    pushes += 1;
  }

  return { broadcast: true, pushes };
}

export function createPaymentNotifyDeps(service: SupabaseClient): PaymentNotifyDeps {
  return {
    service,
    realtime: createRealtimeBroadcastClient(),
    fcm: createFcmClient(async (url, init) => {
      const res = await fetch(url, init);
      return { ok: res.ok, status: res.status, body: await res.text() };
    }),
  };
}

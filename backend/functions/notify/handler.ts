import { z } from 'zod';
import { loadDispatchCfg } from '../_shared/cfg.ts';
import { createFcmClient, type FcmClient } from '../_shared/fcm.ts';
import { jsonResponse, requestId } from '../_shared/http.ts';
import {
  createRealtimeBroadcastClient,
  type RealtimeBroadcastClient,
} from '../_shared/realtime.ts';
import {
  forbiddenUnlessServiceRole,
  type ServiceCaller,
  serviceCallerFromAuthorization,
} from '../_shared/authz.ts';
import { createServiceClient } from '../_shared/supabase.ts';
import type { SupabaseClient } from '@supabase/supabase-js';

export const notifyRequestSchema = z.discriminatedUnion('kind', [
  z.object({
    kind: z.literal('trip_request'),
    trip_id: z.string().uuid(),
  }),
  z.object({
    kind: z.literal('sos'),
    sos_id: z.string().uuid(),
  }),
  z.object({
    kind: z.literal('sos_ack'),
    sos_id: z.string().uuid(),
  }),
  z.object({
    kind: z.literal('trip_message'),
    trip_id: z.string().uuid(),
    recipient_id: z.string().uuid(),
  }),
]);

export type NotifyRequest = z.infer<typeof notifyRequestSchema>;

type DeviceTokenRow = {
  token: string;
  platform: string;
};

type SafetyAdminRow = {
  id: string;
  phone_e164: string | null;
};

export type NotifyDeps = {
  service: SupabaseClient;
  realtime: RealtimeBroadcastClient;
  fcm: FcmClient;
  log?: (entry: Record<string, unknown>) => void;
  caller: ServiceCaller;
};

function phoneSuffix(phone: string | null | undefined): string {
  if (!phone) return '????';
  const digits = phone.replace(/\D/g, '');
  return digits.slice(-4) || '????';
}

async function smsProvider(service: SupabaseClient): Promise<string> {
  const { data, error } = await service.rpc('cfg', { p_key: 'sms.provider', p_city: null });
  if (error) throw new Error(error.message);
  if (typeof data === 'string') return data.replace(/^"|"$/g, '');
  // Fail closed: a missing setting must never silently fall back to log mode.
  if (data == null) throw new Error('sms.provider is not configured');
  return String(data);
}

async function notifySafetyOnCall(
  deps: NotifyDeps,
  sosId: string,
): Promise<{ fcm_sent: number; sms_sent: number }> {
  const { data: admins, error: adminError } = await deps.service
    .from('admin_users')
    .select('id, profiles!inner(phone_e164)')
    .in('role', ['safety', 'ops_lead'])
    .is('disabled_at', null);

  if (adminError) {
    throw new Error(adminError.message);
  }

  const adminRows = (admins ?? []) as Array<
    { id: string; profiles: { phone_e164: string | null } | { phone_e164: string | null }[] }
  >;
  const safetyAdmins: SafetyAdminRow[] = adminRows.map((row) => {
    const profile = Array.isArray(row.profiles) ? row.profiles[0] : row.profiles;
    return { id: row.id, phone_e164: profile?.phone_e164 ?? null };
  });

  let fcmSent = 0;
  for (const admin of safetyAdmins) {
    const { data: tokens, error: tokenError } = await deps.service
      .from('device_tokens')
      .select('token, platform')
      .eq('profile_id', admin.id);

    if (tokenError) {
      throw new Error(tokenError.message);
    }

    for (const row of (tokens ?? []) as DeviceTokenRow[]) {
      await deps.fcm.sendDataMessage({
        token: row.token,
        data: {
          type: 'sos',
          sos_id: sosId,
        },
        ttlSeconds: 300,
        collapseKey: `sos_${sosId}`,
        priority: 'high',
      });
      fcmSent += 1;
    }
  }

  const provider = await smsProvider(deps.service);
  let smsSent = 0;
  for (const admin of safetyAdmins) {
    if (!admin.phone_e164) continue;
    if (provider === 'log') {
      deps.log?.({
        event: 'sms_sos_log',
        provider,
        sos_id: sosId,
        admin_id: admin.id,
        phone_suffix: phoneSuffix(admin.phone_e164),
      });
      smsSent += 1;
    }
  }

  return { fcm_sent: fcmSent, sms_sent: smsSent };
}

type SosAlertRow = {
  id: string;
  raised_by: string;
  raised_role: string;
};

async function notifyRaiserSosAck(
  deps: NotifyDeps,
  sosId: string,
): Promise<{ fcm_sent: number }> {
  const { data: sosRow, error: sosError } = await deps.service
    .from('sos_alerts')
    .select('id, raised_by, raised_role')
    .eq('id', sosId)
    .single();

  if (sosError || !sosRow) {
    throw new Error('NOT_FOUND');
  }

  const sos = sosRow as SosAlertRow;
  const app = sos.raised_role === 'driver' ? 'driver' : 'rider';

  const { data: tokens, error: tokenError } = await deps.service
    .from('device_tokens')
    .select('token, platform')
    .eq('profile_id', sos.raised_by)
    .eq('app', app);

  if (tokenError) {
    throw new Error(tokenError.message);
  }

  let fcmSent = 0;
  for (const row of (tokens ?? []) as DeviceTokenRow[]) {
    await deps.fcm.sendDataMessage({
      token: row.token,
      data: {
        type: 'sos_ack',
        sos_id: sosId,
      },
      ttlSeconds: 300,
      collapseKey: `sos_ack_${sosId}`,
      priority: 'high',
    });
    fcmSent += 1;
  }

  return { fcm_sent: fcmSent };
}

async function tripDriverId(
  service: SupabaseClient,
  tripId: string,
): Promise<{ driverId: string; cityId: string; expiresAt: string }> {
  const { data, error } = await service
    .from('trips')
    .select('driver_id, expires_at, journeys(city_id)')
    .eq('id', tripId)
    .single();

  if (error || !data) {
    throw new Error('NOT_FOUND');
  }

  const journey = data.journeys as { city_id: string } | { city_id: string }[] | null;
  const cityId = Array.isArray(journey) ? journey[0]?.city_id : journey?.city_id;
  if (!cityId) {
    throw new Error('NOT_FOUND');
  }

  return {
    driverId: data.driver_id as string,
    cityId,
    expiresAt: data.expires_at as string,
  };
}

export async function handleNotify(
  body: NotifyRequest,
  deps: NotifyDeps,
): Promise<Response> {
  const rid = requestId();
  const denied = forbiddenUnlessServiceRole(deps.caller, rid);
  if (denied) return denied;

  if (body.kind === 'trip_request') {
    const { driverId, cityId, expiresAt } = await tripDriverId(deps.service, body.trip_id);

    const { data: tripView, error: viewError } = await deps.service.rpc('build_trip_view', {
      p_trip_id: body.trip_id,
      p_viewer_id: driverId,
    });
    if (viewError) {
      throw new Error(viewError.message);
    }

    await deps.realtime.send({
      topic: `driver:${driverId}`,
      event: 'trip_request',
      payload: {
        type: 'trip_request',
        trip: tripView,
        expires_at: expiresAt,
      },
      private: true,
    });

    const dispatchCfg = await loadDispatchCfg(deps.service, cityId);

    const { data: tokens, error: tokenError } = await deps.service
      .from('device_tokens')
      .select('token, platform')
      .eq('profile_id', driverId)
      .eq('app', 'driver');

    if (tokenError) {
      throw new Error(tokenError.message);
    }

    let pushes = 0;
    for (const row of (tokens ?? []) as DeviceTokenRow[]) {
      await deps.fcm.sendDataMessage({
        token: row.token,
        data: {
          type: 'trip_request',
          trip_id: body.trip_id,
        },
        ttlSeconds: dispatchCfg.requestTtlS,
        collapseKey: `trip_${body.trip_id}`,
        priority: 'high',
      });
      pushes += 1;
    }

    return jsonResponse({
      data: {
        kind: body.kind,
        trip_id: body.trip_id,
        driver_id: driverId,
        fcm_sent: pushes,
      },
      meta: { request_id: rid },
    });
  }

  if (body.kind === 'trip_message') {
    // Wake-up only: no message text leaves Postgres; the app fetches on open.
    const { data: tokens, error: tokenError } = await deps.service
      .from('device_tokens')
      .select('token, platform')
      .eq('profile_id', body.recipient_id);
    if (tokenError) {
      throw new Error(tokenError.message);
    }
    let pushes = 0;
    for (const row of (tokens ?? []) as DeviceTokenRow[]) {
      await deps.fcm.sendDataMessage({
        token: row.token,
        data: { type: 'trip_message', trip_id: body.trip_id },
        ttlSeconds: 600,
        collapseKey: `chat_${body.trip_id}`,
        priority: 'high',
      });
      pushes += 1;
    }
    return jsonResponse({
      data: { kind: body.kind, trip_id: body.trip_id, fcm_sent: pushes },
      meta: { request_id: rid },
    });
  }

  if (body.kind === 'sos') {
    const { data: sosRow, error: sosError } = await deps.service
      .from('sos_alerts')
      .select('id')
      .eq('id', body.sos_id)
      .single();

    if (sosError || !sosRow) {
      throw new Error('NOT_FOUND');
    }

    const delivery = await notifySafetyOnCall(deps, body.sos_id);
    const contacts = await notifyEmergencyContacts(deps, body.sos_id);

    return jsonResponse({
      data: {
        kind: body.kind,
        sos_id: body.sos_id,
        fcm_sent: delivery.fcm_sent,
        sms_sent: delivery.sms_sent,
        contact_fcm_sent: contacts.fcm_sent,
      },
      meta: { request_id: rid },
    });
  }

  if (body.kind === 'sos_ack') {
    const delivery = await notifyRaiserSosAck(deps, body.sos_id);

    return jsonResponse({
      data: {
        kind: body.kind,
        sos_id: body.sos_id,
        fcm_sent: delivery.fcm_sent,
      },
      meta: { request_id: rid },
    });
  }

  throw new Error(`Unsupported notify kind`);
}

async function notifyEmergencyContacts(
  deps: NotifyDeps,
  sosId: string,
): Promise<{ fcm_sent: number }> {
  const { data: sosRow, error: sosError } = await deps.service
    .from('sos_alerts')
    .select('id, raised_by')
    .eq('id', sosId)
    .single();

  if (sosError || !sosRow) return { fcm_sent: 0 };
  const raisedBy = (sosRow as { raised_by?: string }).raised_by;
  if (!raisedBy) return { fcm_sent: 0 };

  const { data: contacts, error: contactError } = await deps.service
    .from('emergency_contacts')
    .select('display_name, phone_e164')
    .eq('profile_id', raisedBy);

  if (contactError) {
    throw new Error(contactError.message);
  }

  let fcmSent = 0;
  for (const contact of (contacts ?? []) as Array<{ phone_e164: string }>) {
    const { data: profiles, error: profileError } = await deps.service
      .from('profiles')
      .select('id')
      .eq('phone_e164', contact.phone_e164);

    if (profileError) throw new Error(profileError.message);
    const profileId = (profiles as Array<{ id: string }> | null)?.[0]?.id;
    if (!profileId) continue;

    const { data: tokens, error: tokenError } = await deps.service
      .from('device_tokens')
      .select('token, platform')
      .eq('profile_id', profileId);

    if (tokenError) throw new Error(tokenError.message);
    for (const row of (tokens ?? []) as DeviceTokenRow[]) {
      await deps.fcm.sendDataMessage({
        token: row.token,
        data: { type: 'sos_contact', sos_id: sosId },
        ttlSeconds: 300,
        collapseKey: `sos_contact_${sosId}`,
        priority: 'high',
      });
      fcmSent += 1;
    }
  }

  return { fcm_sent: fcmSent };
}

export function handleNotifyDefault(
  body: NotifyRequest,
  authorization: string | null,
): Promise<Response> {
  return handleNotify(body, {
    service: createServiceClient(),
    realtime: createRealtimeBroadcastClient(),
    fcm: createFcmClient(async (url, init) => {
      const res = await fetch(url, init);
      return { ok: res.ok, status: res.status, body: await res.text() };
    }),
    caller: serviceCallerFromAuthorization(authorization),
  });
}

/** FCM HTTP v1 provider interface (ADR-0011). No Firebase Admin SDK — raw HTTP only. */

export type FcmDataMessage = {
  token: string;
  data: Record<string, string>;
  ttlSeconds: number;
  collapseKey?: string;
  priority?: 'high' | 'normal';
};

export type FcmSendResult = {
  messageId: string;
};

export interface FcmClient {
  sendDataMessage(message: FcmDataMessage): Promise<FcmSendResult>;
}

export type FcmHttpResponse = {
  ok: boolean;
  status: number;
  body: string;
};

export function createFcmClient(
  fetchFn: (url: string, init: RequestInit) => Promise<FcmHttpResponse>,
): FcmClient {
  const projectId = Deno.env.get('FCM_PROJECT_ID');
  const accessToken = Deno.env.get('FCM_ACCESS_TOKEN');

  return {
    async sendDataMessage(message: FcmDataMessage): Promise<FcmSendResult> {
      if (!projectId || !accessToken) {
        return { messageId: 'stub-no-fcm-config' };
      }

      const url =
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
      const res = await fetchFn(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: message.token,
            data: message.data,
            android: {
              priority: message.priority ?? 'high',
              ttl: `${message.ttlSeconds}s`,
              collapse_key: message.collapseKey,
            },
            apns: {
              headers: {
                'apns-priority': message.priority === 'normal' ? '5' : '10',
                'apns-expiration': String(
                  Math.floor(Date.now() / 1000) + message.ttlSeconds,
                ),
              },
              payload: { aps: { 'content-available': 1 } },
            },
          },
        }),
      });

      if (!res.ok) {
        throw new Error(`FCM send failed (${res.status}): ${res.body}`);
      }

      let messageId = 'fcm-ok';
      try {
        const parsed = JSON.parse(res.body) as { name?: string };
        messageId = parsed.name ?? messageId;
      } catch {
        // keep default id
      }

      return { messageId };
    },
  };
}

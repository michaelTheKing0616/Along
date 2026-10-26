/**
 * Rider <-> driver contact relay (PR #17).
 *
 * Clients never receive the other party's number in a trip payload. They ask
 * the trip-contact Edge Function for a short-lived contact action, which a
 * ContactProvider builds:
 *
 * - `tel` (default, dev/staging): returns a tel:/sms: URI for the real number.
 *   NOT masked. The number reaches the device only when the user taps Call or
 *   Message on a live trip, and every hand-out is logged by phone suffix.
 * - `termii` / `africastalking`: masked-number adapters. Stubs until Along has
 *   a provider account: they need CONTACT_PROVIDER_API_KEY and
 *   CONTACT_PROXY_NUMBER, plus the provider's session API, and fail closed
 *   (503 CONTACT_UNAVAILABLE) rather than leak the real number.
 */

export type ContactChannel = 'call' | 'sms';

export type ContactSessionParams = {
  tripId: string;
  channel: ContactChannel;
  callerPhone: string;
  targetPhone: string;
  ttlSeconds: number;
};

export type ContactAction = {
  channel: ContactChannel;
  uri: string;
  masked: boolean;
  expires_at: string;
};

export interface ContactProvider {
  readonly name: string;
  createSession(params: ContactSessionParams): Promise<ContactAction>;
}

export class ContactProviderNotConfigured extends Error {
  constructor(provider: string, missing: string[]) {
    super(`contact provider ${provider} needs ${missing.join(', ')}`);
    this.name = 'ContactProviderNotConfigured';
  }
}

function expiresAt(ttlSeconds: number, now: Date): string {
  return new Date(now.getTime() + ttlSeconds * 1000).toISOString();
}

export function telProvider(now: () => Date = () => new Date()): ContactProvider {
  return {
    name: 'tel',
    createSession(p) {
      const scheme = p.channel === 'call' ? 'tel' : 'sms';
      return Promise.resolve({
        channel: p.channel,
        uri: `${scheme}:${p.targetPhone}`,
        masked: false,
        expires_at: expiresAt(p.ttlSeconds, now()),
      });
    },
  };
}

/**
 * Masked-number adapter shape for Termii / Africa's Talking style providers:
 * the provider bridges caller -> proxy number -> target for ttlSeconds. The
 * session call itself is not implemented until credentials and the chosen
 * provider's API contract are confirmed.
 */
export function maskedProvider(
  name: 'termii' | 'africastalking',
  env: { apiKey?: string; proxyNumber?: string },
): ContactProvider {
  return {
    name,
    createSession() {
      const missing = [
        ...(env.apiKey ? [] : ['CONTACT_PROVIDER_API_KEY']),
        ...(env.proxyNumber ? [] : ['CONTACT_PROXY_NUMBER']),
      ];
      if (missing.length) {
        return Promise.reject(new ContactProviderNotConfigured(name, missing));
      }
      return Promise.reject(
        new ContactProviderNotConfigured(name, [`${name} session API integration`]),
      );
    },
  };
}

export function contactProviderFromEnv(
  get: (key: string) => string | undefined,
): ContactProvider {
  const name = (get('CONTACT_PROVIDER') ?? 'tel').trim().toLowerCase();
  if (name === 'tel') return telProvider();
  if (name === 'termii' || name === 'africastalking') {
    return maskedProvider(name, {
      apiKey: get('CONTACT_PROVIDER_API_KEY'),
      proxyNumber: get('CONTACT_PROXY_NUMBER'),
    });
  }
  throw new ContactProviderNotConfigured(name, ['a supported CONTACT_PROVIDER']);
}

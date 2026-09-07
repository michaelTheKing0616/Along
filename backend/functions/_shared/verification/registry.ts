import type { VerificationProvider } from './types.ts';
import { createVerifyMeStubProvider } from './providers/verifyme_stub.ts';

const providers = new Map<string, VerificationProvider>([
  ['verifyme', createVerifyMeStubProvider()],
  ['mock-verifyme', createVerifyMeStubProvider()],
]);

export function resolveVerificationProvider(providerName: string): VerificationProvider {
  const normalized = providerName.trim().toLowerCase();
  const provider = providers.get(normalized);
  if (!provider) {
    throw new Error(`UNKNOWN_VERIFICATION_PROVIDER:${normalized}`);
  }
  return provider;
}

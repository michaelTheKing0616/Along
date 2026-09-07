import type { VerificationProvider, VerificationProviderResult } from '../types.ts';

/** In-process VerifyMe adapter — never calls the live API (P10-A-01). */
export function createVerifyMeStubProvider(): VerificationProvider {
  return {
    name: 'verifyme',
    runOcr(_path: string, documentType: string): Promise<VerificationProviderResult> {
      if (documentType === 'nin') {
        return Promise.resolve({
          fields: {
            full_name: 'Test Driver',
            id_number: '12345678901',
            dob: '1990-05-15',
          },
          provider: 'verifyme',
          provider_reference: 'stub-verifyme-nin',
        });
      }

      if (documentType === 'drivers_license') {
        return Promise.resolve({
          fields: {
            full_name: 'Test Driver',
            license_number: 'LAG1234567',
            expiry: '2028-12-01',
          },
          provider: 'verifyme',
          provider_reference: 'stub-verifyme-license',
        });
      }

      return Promise.resolve({
        fields: { full_name: 'Test Driver' },
        provider: 'verifyme',
        provider_reference: 'stub-verifyme-generic',
      });
    },
  };
}

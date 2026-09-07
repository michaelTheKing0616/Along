/** Pluggable verification upstream (Phase 10 — keyed by countries.verification_schema.provider). */
export type VerificationOcrFields = Record<string, string>;

export type VerificationProviderResult = {
  fields: VerificationOcrFields;
  provider: string;
  provider_reference: string;
};

export type VerificationProvider = {
  readonly name: string;
  runOcr(path: string, documentType: string): Promise<VerificationProviderResult>;
};

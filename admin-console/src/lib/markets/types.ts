export type MarketsTab = 'countries' | 'verification' | 'regulatory' | 'i18n' | 'payment';

export type PaymentProvider = 'paystack' | 'flutterwave' | 'none';

export interface VerificationDocRow {
  type: string;
  label: string;
  pattern: string;
  provider: string;
}

export interface CountryRow {
  code: string;
  name: string;
  currency_code: string;
  currency_minor_units: number;
  currency_symbol: string;
  phone_prefix: string;
  default_locale: string;
  timezone: string;
  deployment_id: string;
  verification_schema: VerificationDocRow[];
  regulatory_flags: Record<string, unknown>;
  active: boolean;
  payment_provider: PaymentProvider;
}

export interface DeploymentOption {
  id: string;
  tenant_name: string;
}

export interface I18nCoverageRow {
  locale: string;
  total_keys: number;
  translated_keys: number;
  coverage_pct: number;
  source: string;
}

export interface CountryFormInput {
  code: string;
  name: string;
  currency_code: string;
  currency_symbol: string;
  currency_minor_units: number;
  phone_prefix: string;
  default_locale: string;
  timezone: string;
  deployment_id: string;
  active: boolean;
  women_only_matching: boolean;
  payment_provider: PaymentProvider;
  verification_schema: VerificationDocRow[];
}

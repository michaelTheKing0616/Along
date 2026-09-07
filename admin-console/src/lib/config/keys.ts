export type ConfigScope = 'global' | 'country' | 'city' | 'corridor';

export type ConfigKeyMeta = {
  key: string;
  description: string | null;
  allowedScopes: ConfigScope[];
  readOnly: boolean;
  valueSchema: Record<string, unknown> | null;
};

export const CONFIG_SCOPE_LABELS: Record<ConfigScope, string> = {
  global: 'Global',
  country: 'Country',
  city: 'City',
  corridor: 'Corridor',
};

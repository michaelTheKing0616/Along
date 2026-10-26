/**
 * Short display names for Nigerian bank codes (Paystack / NIBSS codes). Used to
 * label payouts "<bank> ••1234". Unknown codes return null; the app then shows
 * "Bank ••1234".
 */
const NG_BANK_NAMES: Record<string, string> = {
  '044': 'Access',
  '063': 'Access',
  '023': 'Citibank',
  '050': 'Ecobank',
  '070': 'Fidelity',
  '011': 'First Bank',
  '214': 'FCMB',
  '058': 'GTBank',
  '030': 'Heritage',
  '301': 'Jaiz',
  '082': 'Keystone',
  '50211': 'Kuda',
  '50515': 'Moniepoint',
  '999992': 'OPay',
  '999991': 'PalmPay',
  '076': 'Polaris',
  '101': 'Providus',
  '221': 'Stanbic IBTC',
  '068': 'Standard Chartered',
  '232': 'Sterling',
  '100': 'Suntrust',
  '032': 'Union Bank',
  '033': 'UBA',
  '215': 'Unity',
  '035': 'Wema',
  '057': 'Zenith',
};

export function ngBankName(bankCode: string): string | null {
  return NG_BANK_NAMES[bankCode.trim()] ?? null;
}

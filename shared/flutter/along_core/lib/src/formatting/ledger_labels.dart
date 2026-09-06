/// Human-readable labels for ledger entry types and driver standing.
/// Never expose raw enum names in UI (doc 06 D-19, TS-UI-05).
String ledgerEntryLabel(
  String entryType, {
  String? destinationLabel,
  String? memo,
}) {
  final destination = destinationLabel?.trim();
  switch (entryType) {
    case 'cash_commission_debit':
      if (destination != null && destination.isNotEmpty) {
        return 'Along fee · Trip to $destination';
      }
      return 'Along fee';
    case 'digital_settlement_credit':
      if (memo != null && memo.toLowerCase().contains('agent')) {
        return 'Settlement · Agent';
      }
      return 'Settlement · Paystack';
    case 'onboarding_deposit':
      return 'Deposit';
    case 'deposit_drawdown':
      return 'Deposit used';
    case 'payout_debit':
      return 'Payout to bank';
    case 'manual_adjustment':
      return memo?.trim().isNotEmpty == true ? memo!.trim() : 'Adjustment';
    default:
      return 'Transaction';
  }
}

String standingLabel(String standing) => switch (standing) {
      'good_standing' => 'Good standing',
      'warned' => 'Needs attention',
      'matching_paused' => 'Matching paused',
      'deactivated' => 'Account deactivated',
      _ => 'Account status',
    };

bool isRawLedgerEnum(String text) {
  const raw = {
    'cash_commission_debit',
    'digital_settlement_credit',
    'onboarding_deposit',
    'deposit_drawdown',
    'payout_debit',
    'manual_adjustment',
    'good_standing',
    'warned',
    'matching_paused',
    'deactivated',
  };
  return raw.contains(text);
}

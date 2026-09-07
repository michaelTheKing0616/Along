import 'package:along_core/along_core.dart';

/// Formats a fare amount in major units for display.
///
/// Uses the bundled Inter subset so currency symbols (e.g. U+20A6) render correctly (TS-DS-02).
String formatMoney(int amountMajor, {String currency = 'NGN', String? currencySymbol}) {
  final symbol = currencySymbol ?? _symbolForCurrency(currency);
  final formatted = amountMajor.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '$symbol$formatted';
}

String _symbolForCurrency(String currency) => switch (currency) {
      'NGN' => '₦',
      _ => '$currency ',
    };

/// Convenience when a [Money] value is already available.
String formatMoneyValue(Money money, {String? currencySymbol}) =>
    formatMoney(
      money.amount.round().toBigInt().toInt(),
      currency: money.currency,
      currencySymbol: currencySymbol,
    );

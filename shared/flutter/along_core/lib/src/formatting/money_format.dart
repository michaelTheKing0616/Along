import 'package:along_core/src/value/money.dart';
import 'package:intl/intl.dart';

/// Formats [money] for display (e.g. `₦450`).
String formatMoney(
  Money money, {
  String locale = 'en_NG',
  bool showDecimals = false,
}) {
  final symbol = _currencySymbol(money.currency);
  final pattern = showDecimals ? '$symbol#,##0.00' : '$symbol#,##0';
  final formatter = NumberFormat(pattern, locale);
  final value = showDecimals ? money.amount.toDouble() : money.amount.round().toDouble();
  return formatter.format(value);
}

/// Spoken amount for TTS (English Nigeria baseline).
String formatMoneySpoken(Money money, {String locale = 'en_NG'}) {
  if (locale.startsWith('en')) {
    final major = money.amount.round().toBigInt().toInt();
    final unit = money.currency == 'NGN' ? 'naira' : money.currency.toLowerCase();
    if (major == 0) return 'zero $unit';
    return '${_englishNumber(major)} $unit';
  }
  try {
    return formatMoney(money, locale: locale);
  } catch (_) {
    return '${money.toApiString()} ${money.currency}';
  }
}

String _currencySymbol(String currency) => switch (currency) {
      'NGN' => '₦',
      _ => '$currency ',
    };

String _englishNumber(int n) {
  if (n < 0) return 'negative ${_englishNumber(-n)}';
  if (n == 0) return 'zero';
  if (n < 20) {
    const ones = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    return ones[n];
  }
  if (n < 100) {
    const tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
    final rem = n % 10;
    final base = tens[n ~/ 10];
    return rem == 0 ? base : '$base ${_englishNumber(rem)}';
  }
  if (n < 1000) {
    final hundreds = n ~/ 100;
    final rem = n % 100;
    final head = '${_englishNumber(hundreds)} hundred';
    return rem == 0 ? head : '$head ${_englishNumber(rem)}';
  }
  if (n < 1_000_000) {
    final thousands = n ~/ 1000;
    final rem = n % 1000;
    final head = '${_englishNumber(thousands)} thousand';
    return rem == 0 ? head : '$head ${_englishNumber(rem)}';
  }
  return n.toString();
}

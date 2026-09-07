import 'package:along_core/src/formatting/money_format.dart';
import 'package:along_core/src/value/money.dart';

/// Country-aware money display helper (symbol from `countries`, code from [Money]).
class MoneyFormatter {
  const MoneyFormatter({
    required this.currencyCode,
    required this.currencySymbol,
    this.locale = 'en_NG',
  });

  final String currencyCode;
  final String currencySymbol;
  final String locale;

  String format(Money money) => formatMoneyWithMeta(
        money,
        currencySymbol: currencySymbol,
        locale: locale,
      );

  String formatMajor(int amountMajor, {String? currencyCodeOverride}) =>
      format(
        Money.parse(
          amountMajor.toString(),
          currency: currencyCodeOverride ?? currencyCode,
        ),
      );
}

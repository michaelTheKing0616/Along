import 'package:decimal/decimal.dart';
import 'package:along_design/along_design.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-13 Price keypad — large numeric entry with suggested chips (doc 06 D-13).
class PriceKeypadSheet extends StatefulWidget {
  const PriceKeypadSheet({
    super.key,
    required this.initialAmount,
    required this.suggestedAmounts,
    required this.onSet,
  });

  final Decimal initialAmount;
  final List<Decimal> suggestedAmounts;
  final ValueChanged<Decimal> onSet;

  static Future<void> show(
    BuildContext context, {
    required Decimal initialAmount,
    required List<Decimal> suggestedAmounts,
    required ValueChanged<Decimal> onSet,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AlongColors.surface0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AlongRadius.lg.x)),
      ),
      builder: (context) => PriceKeypadSheet(
        initialAmount: initialAmount,
        suggestedAmounts: suggestedAmounts,
        onSet: onSet,
      ),
    );
  }

  @override
  State<PriceKeypadSheet> createState() => _PriceKeypadSheetState();
}

class _PriceKeypadSheetState extends State<PriceKeypadSheet> {
  late String _digits;

  @override
  void initState() {
    super.initState();
    _digits = widget.initialAmount.toBigInt().toString();
    if (_digits == '0') _digits = '';
  }

  Decimal get _current =>
      _digits.isEmpty ? Decimal.zero : Decimal.parse(_digits);

  void _append(String digit) {
    setState(() {
      if (_digits.length >= 6) return;
      _digits += digit;
    });
  }

  void _backspace() {
    setState(() {
      if (_digits.isEmpty) return;
      _digits = _digits.substring(0, _digits.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final display = formatMoney(_current.toBigInt().toInt());

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AlongSpace.s24,
          right: AlongSpace.s24,
          top: AlongSpace.s16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AlongSpace.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.routePriceKeypadTitle,
              style: AlongText.heading2,
            ),
            const SizedBox(height: AlongSpace.s16),
            Text(
              display,
              key: const Key('price_keypad_display'),
              style: AlongText.displayL,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AlongSpace.s16),
            Wrap(
              spacing: AlongSpace.s8,
              runSpacing: AlongSpace.s8,
              children: [
                for (final amount in widget.suggestedAmounts)
                  ActionChip(
                    key: Key('price_chip_${amount.toBigInt()}'),
                    label: Text(formatMoney(amount.toBigInt().toInt())),
                    onPressed: () => setState(() {
                      _digits = amount.toBigInt().toString();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AlongSpace.s16),
            _KeypadGrid(
              onDigit: _append,
              onBackspace: _backspace,
            ),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('price_keypad_set_button'),
              label: l10n.routePriceKeypadSet,
              onPressed: () {
                widget.onSet(_current);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KeypadGrid extends StatelessWidget {
  const _KeypadGrid({
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AlongSpace.s4),
                    child: _KeypadKey(
                      label: key,
                      onTap: key.isEmpty
                          ? null
                          : key == '⌫'
                              ? onBackspace
                              : () => onDigit(key),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AlongColors.surface100,
      borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AlongRadius.sm.x),
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: AlongText.displayL.copyWith(fontSize: 28),
            ),
          ),
        ),
      ),
    );
  }
}

List<Decimal> defaultPriceSuggestions(Decimal around) {
  final base = around.toBigInt().toInt();
  final values = {
    base,
    base - 50,
    base - 100,
    base + 50,
  }.where((v) => v >= 0).toList()
    ..sort();
  return values.map((v) => Decimal.fromInt(v)).toList(growable: false);
}

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';

/// D-08 payment toast for `payment_received` Broadcast (doc 06).
class PaymentToast extends StatelessWidget {
  const PaymentToast({
    super.key,
    required this.amount,
    required this.onDismiss,
  });

  final Money amount;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('payment_toast'),
      elevation: 6,
      borderRadius: BorderRadius.circular(AlongRadius.sm.x),
      color: AlongColors.semanticSuccessFill,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s16,
          vertical: AlongSpace.s12,
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AlongColors.surface0),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: Text(
                '${formatMoney(amount)} received',
                style: AlongText.bodyStrong.copyWith(color: AlongColors.surface0),
              ),
            ),
            IconButton(
              key: const Key('payment_toast_dismiss'),
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: AlongColors.surface0),
            ),
          ],
        ),
      ),
    );
  }
}

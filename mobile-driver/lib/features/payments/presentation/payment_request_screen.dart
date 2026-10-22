import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart' hide formatMoney;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/payments/presentation/payment_request_controller.dart';
import 'package:mobile_driver/features/payments/presentation/widgets/along_qr_widget.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-26 Payment request — dynamic QR + live paid state (doc 06).
class PaymentRequestScreen extends ConsumerWidget {
  const PaymentRequestScreen({super.key, required this.args});

  final PaymentRequestArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(paymentRequestControllerFamilyProvider(args));

    return Scaffold(
      key: const Key('payment_request_screen'),
      appBar: AppBar(
        title: Text(l10n.paymentRequestTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: switch (state.phase) {
          PaymentRequestPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          PaymentRequestPhase.error => Center(
              child: Text(
                _errorText(l10n, state.errorMessage),
                style: AlongText.body,
                textAlign: TextAlign.center,
              ),
            ),
          PaymentRequestPhase.expired => Center(
              child: Text(l10n.paymentRequestExpired, style: AlongText.body),
            ),
          PaymentRequestPhase.paid => _PaidState(
              amount: state.paidEvent!.amount,
              driverAmount: state.paidEvent!.driverAmount,
              l10n: l10n,
              onDone: () => context.pop(true),
            ),
          PaymentRequestPhase.waiting => _WaitingState(
              payload: state.payload!,
              riderName: state.riderName,
              remainingSeconds: state.remainingSeconds ?? 0,
              l10n: l10n,
            ),
        },
      ),
    );
  }

  String _errorText(AppLocalizations l10n, String? code) => switch (code) {
        'digital_disabled' => l10n.paymentRequestDigitalDisabled,
        'token_mismatch' => l10n.paymentRequestTokenError,
        _ => l10n.errorGeneric,
      };
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({
    required this.payload,
    required this.riderName,
    required this.remainingSeconds,
    required this.l10n,
  });

  final PaymentRequestPayload payload;
  final String? riderName;
  final int remainingSeconds;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          formatMoney(payload.amount),
          style: AlongText.displayL,
          textAlign: TextAlign.center,
        ),
        if (riderName != null) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            l10n.paymentRequestForRider(riderName!),
            style: AlongText.body,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AlongSpace.s24),
        Center(
          child: AlongQrWidget(
            key: const Key('payment_request_qr'),
            data: payload.url,
          ),
        ),
        const SizedBox(height: AlongSpace.s16),
        Text(
          l10n.paymentRequestCountdown(remainingSeconds),
          style: AlongText.caption.copyWith(color: AlongColors.ink500),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Text(
          l10n.paymentRequestWaiting,
          style: AlongText.bodyStrong,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PaidState extends StatelessWidget {
  const _PaidState({
    required this.amount,
    required this.driverAmount,
    required this.l10n,
    required this.onDone,
  });

  final Money amount;
  final Money driverAmount;
  final AppLocalizations l10n;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('payment_request_paid'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 72,
          color: AlongColors.semanticSuccessFill,
        ),
        const SizedBox(height: AlongSpace.s16),
        Text(
          l10n.paymentRequestPaidLine(formatMoney(amount)),
          style: AlongText.heading1.copyWith(
            color: AlongColors.semanticSuccessFill,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AlongSpace.s8),
        Text(
          l10n.paymentRequestBankLine(formatMoney(driverAmount)),
          style: AlongText.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AlongSpace.s24),
        AlongButton(
          key: const Key('payment_request_done'),
          label: l10n.paymentRequestDone,
          onPressed: onDone,
        ),
      ],
    );
  }
}

import 'dart:async';

import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/features/negotiation/domain/pricing_helpers.dart';
import 'package:mobile_driver/features/negotiation/presentation/driver_pricing_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// Driver-side Along Pricing overlay (counterpart to rider R-16).
class DriverPricingSheet extends ConsumerWidget {
  const DriverPricingSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(driverPricingNotifierProvider);
    final controller = ref.read(driverPricingNotifierProvider.notifier);

    if (state.isTerminal) {
      return _TerminalOverlay(
        kind: state.terminal,
        l10n: l10n,
        onDismiss: controller.dismissTerminal,
      );
    }

    final view = state.view;
    if (view == null) {
      return const SizedBox.shrink();
    }

    final variant = negotiationVariantFor(
      context: view.context,
      etaBand: view.etaBand,
    );
    final canCounter = view.proposedBy == 'rider';

    return Material(
      key: const Key('driver_pricing_sheet'),
      color: AlongColors.surface0,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.lastRiderNaira != null && view.proposedBy == 'rider')
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AlongSpace.s16,
                    AlongSpace.s16,
                    AlongSpace.s16,
                    0,
                  ),
                  child: Text(
                    l10n.pricingRiderOffer(formatMoney(state.lastRiderNaira!)),
                    key: const Key('driver_pricing_rider_offer'),
                    style: AlongText.bodyStrong,
                  ),
                ),
              NegotiationSheet(
                key: const Key('driver_negotiation_sheet'),
                variant: variant,
                anchorNaira: view.anchorNaira,
                chipSteps: view.chipStepsNaira,
                proposedNaira: state.displayNaira,
                splitNaira: state.splitNaira,
                roundNumber: view.round,
                roundCap: view.roundCap,
                countdownSeconds: state.countdownSeconds,
                countdownTotal: state.countdownTotal,
                onChipStep: canCounter && !state.isSubmitting
                    ? controller.applyChipStep
                    : null,
                onOffer: canCounter && !state.isSubmitting
                    ? () => unawaited(controller.offer())
                    : null,
                onAccept: !state.isSubmitting
                    ? () => unawaited(controller.accept())
                    : null,
                onSkip: !state.isSubmitting
                    ? () => unawaited(controller.skip())
                    : null,
                onSplit: canCounter && !state.isSubmitting
                    ? () => unawaited(controller.splitDifference())
                    : null,
              ),
              if (state.isSubmitting)
                const Padding(
                  padding: EdgeInsets.all(AlongSpace.s16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalOverlay extends StatelessWidget {
  const _TerminalOverlay({
    required this.kind,
    required this.l10n,
    required this.onDismiss,
  });

  final DriverPricingTerminalKind kind;
  final AppLocalizations l10n;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final message = switch (kind) {
      DriverPricingTerminalKind.lapsedTimeout => l10n.pricingLapsed,
      DriverPricingTerminalKind.lapsedOutOfRange => l10n.pricingOutOfRange,
      DriverPricingTerminalKind.declined => l10n.pricingDeclined,
      DriverPricingTerminalKind.none => l10n.errorGeneric,
    };

    return Material(
      color: AlongColors.surface0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, textAlign: TextAlign.center, style: AlongText.body),
              const SizedBox(height: AlongSpace.s16),
              AlongButton(
                label: l10n.pricingDismiss,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

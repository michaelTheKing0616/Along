import 'dart:async';

import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_route_args.dart';
import 'package:mobile_rider/features/pricing/presentation/pricing_controller.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-16 Along Pricing — park / roaming bands / split (doc 06).
class PricingSheetScreen extends ConsumerStatefulWidget {
  const PricingSheetScreen({super.key, required this.args});

  final PricingRouteArgs args;

  @override
  ConsumerState<PricingSheetScreen> createState() => _PricingSheetScreenState();
}

class _PricingSheetScreenState extends ConsumerState<PricingSheetScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pricingRouteArgsProvider.notifier).state = widget.args,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(pricingControllerFamilyProvider(widget.args));
    final controller =
        ref.read(pricingControllerFamilyProvider(widget.args).notifier);

    ref.listen(pricingControllerFamilyProvider(widget.args), (prev, next) {
      if (next.agreedTrip != null && prev?.agreedTrip == null && mounted) {
        context.pushReplacement(
          AppRoutes.requesting,
          extra: RequestingRouteArgs(
            trip: next.agreedTrip!,
            roamingSource: widget.args.context == 'roaming',
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pricingTitle),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.view == null
              ? _ErrorBody(message: state.errorMessage!)
              : _buildBody(context, state, controller, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PricingState state,
    PricingController controller,
    AppLocalizations l10n,
  ) {
    if (state.isTerminal) {
      return _TerminalBody(kind: state.terminal, l10n: l10n);
    }

    final view = state.view;
    if (view == null) {
      return _ErrorBody(message: state.errorMessage ?? l10n.errorGeneric);
    }

    final variant = negotiationVariantFor(
      context: view.context,
      etaBand: view.etaBand,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.driverResponseNaira != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AlongSpace.s16,
                AlongSpace.s16,
                AlongSpace.s16,
                0,
              ),
              child: Text(
                l10n.pricingDriverOffer(formatMoney(state.driverResponseNaira!)),
                style: AlongText.bodyStrong,
              ),
            ),
          NegotiationSheet(
            key: const Key('pricing_negotiation_sheet'),
            variant: variant,
            anchorNaira: view.anchorNaira,
            chipSteps: view.chipStepsNaira,
            proposedNaira: state.displayNaira,
            splitNaira: state.splitNaira,
            roundNumber: view.round,
            roundCap: view.roundCap,
            countdownSeconds: state.countdownSeconds,
            countdownTotal: state.countdownTotal,
            extensionDeltaNaira: widget.args.extensionDeltaNaira,
            onChipStep: state.isSubmitting ? null : controller.applyChipStep,
            onOffer: state.isSubmitting ? null : () => unawaited(controller.offer()),
            onAccept: state.isSubmitting ? null : () => unawaited(controller.accept()),
            onSkip: state.isSubmitting ? null : () => unawaited(controller.skip()),
            onSplit: state.isSubmitting
                ? null
                : () => unawaited(controller.splitDifference()),
          ),
          if (state.isSubmitting)
            const Padding(
              padding: EdgeInsets.all(AlongSpace.s16),
              child: LinearProgressIndicator(),
            ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(AlongSpace.s16),
              child: Text(
                state.errorMessage!,
                style: AlongText.caption.copyWith(color: AlongColors.semanticDanger),
              ),
            ),
        ],
      ),
    );
  }
}

class _TerminalBody extends StatelessWidget {
  const _TerminalBody({required this.kind, required this.l10n});

  final PricingTerminalKind kind;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final message = switch (kind) {
      PricingTerminalKind.lapsedTimeout => l10n.pricingLapsed,
      PricingTerminalKind.lapsedOutOfRange => l10n.pricingOutOfRange,
      PricingTerminalKind.declined => l10n.pricingDeclined,
      PricingTerminalKind.none => l10n.errorGeneric,
    };

    return Center(
      key: Key('pricing_terminal_${kind.name}'),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s24),
        child: Text(message, textAlign: TextAlign.center, style: AlongText.body),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

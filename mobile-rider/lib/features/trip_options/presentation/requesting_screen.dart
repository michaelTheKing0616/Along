import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-10 Requesting — pulsing puck, server countdown, cancel.
class RequestingScreen extends ConsumerStatefulWidget {
  const RequestingScreen({
    super.key,
    required this.trip,
    required this.roamingSource,
  });

  final TripSummary trip;
  final bool roamingSource;

  @override
  ConsumerState<RequestingScreen> createState() => _RequestingScreenState();
}

class _RequestingScreenState extends ConsumerState<RequestingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  TripOptionsState? _preservedPlan;

  @override
  void initState() {
    super.initState();
    _preservedPlan = ref.read(tripOptionsControllerProvider);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final args = RequestingArgs(
      trip: widget.trip,
      roamingSource: widget.roamingSource,
    );
    final state = ref.watch(requestingControllerFamilyProvider(args));

    ref.listen(requestingControllerFamilyProvider(args), (prev, next) {
      if (next.expired && prev?.expired != true) {
        _returnToOptions();
      }
      if (next.cancelled && prev?.cancelled != true) {
        _returnToOptions();
      }
      if (next.accepted && prev?.accepted != true) {
        context.go(AppRoutes.meetVehicle, extra: next.trip);
      }
    });

    final modeLabel = _modeFromTrip(widget.trip);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(color: AlongColors.surface100),
                FadeTransition(
                  opacity: Tween<double>(begin: 0.4, end: 1).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AlongColors.brandYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AlongColors.brandYellow.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AlongSpace.s16),
            decoration: const BoxDecoration(
              color: AlongColors.surface0,
              borderRadius: BorderRadius.vertical(top: AlongRadius.sheet),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.requestingTitle(modeLabel),
                  style: AlongText.heading2,
                ),
                const SizedBox(height: AlongSpace.s8),
                Text(
                  l10n.requestingCountdown(state.remainingSeconds),
                  style: AlongText.numericM,
                ),
                if (state.cascadeMessage) ...[
                  const SizedBox(height: AlongSpace.s8),
                  Text(
                    l10n.requestingFindingAnother,
                    style: AlongText.caption.copyWith(color: AlongColors.ink500),
                  ),
                ],
                if (state.accepted) ...[
                  const SizedBox(height: AlongSpace.s8),
                  Text(
                    l10n.requestingAcceptedPlaceholder,
                    style: AlongText.bodyStrong.copyWith(
                      color: AlongColors.semanticSuccessFill,
                    ),
                  ),
                ],
                if (state.expired) ...[
                  const SizedBox(height: AlongSpace.s8),
                  Text(
                    l10n.requestingExpired,
                    style: AlongText.body.copyWith(color: AlongColors.ink500),
                  ),
                ],
                const SizedBox(height: AlongSpace.s16),
                AlongButton(
                  key: const Key('requesting_cancel'),
                  label: l10n.requestingCancel,
                  variant: AlongButtonVariant.secondary,
                  onPressed: state.expired || state.accepted
                      ? null
                      : () async {
                          await ref
                              .read(requestingControllerFamilyProvider(args)
                                  .notifier)
                              .cancel();
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _returnToOptions() {
    final preserved = _preservedPlan;
    if (preserved != null) {
      ref
          .read(tripOptionsControllerProvider.notifier)
          .preservePlanFrom(preserved);
    }
    if (mounted) {
      context.go(AppRoutes.tripOptions);
    }
  }

  String _modeFromTrip(TripSummary trip) => 'ride';
}

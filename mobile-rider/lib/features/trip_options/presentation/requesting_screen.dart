import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/tenant/tenant_providers.dart';
import 'package:mobile_rider/features/trip_options/presentation/trip_options_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-10 Requesting. The route stays on screen with a pulse at the pickup
/// while the server countdown runs; one quiet Cancel below.
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

class _RequestingScreenState extends ConsumerState<RequestingScreen> {
  TripOptionsState? _preservedPlan;
  int _window = 0;

  @override
  void initState() {
    super.initState();
    _preservedPlan = ref.read(tripOptionsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AlongPalette.of(context);
    final args = RequestingArgs(
      trip: widget.trip,
      roamingSource: widget.roamingSource,
    );
    final state = ref.watch(requestingControllerFamilyProvider(args));

    ref.listen(requestingControllerFamilyProvider(args), (prev, next) {
      if (next.expired && prev?.expired != true) _returnToOptions();
      if (next.cancelled && prev?.cancelled != true) _returnToOptions();
      if (next.accepted && prev?.accepted != true) {
        AlongHaptics.match(context);
        context.go(AppRoutes.meetVehicle, extra: next.trip);
      }
    });

    final trip = widget.trip;
    if (state.remainingSeconds > _window) _window = state.remainingSeconds;
    final fraction = _window == 0 ? 0.0 : state.remainingSeconds / _window;
    final mode = trip.modeLabel.isEmpty ? trip.modeCode : trip.modeLabel;
    final m = state.remainingSeconds ~/ 60;
    final s = (state.remainingSeconds % 60).toString().padLeft(2, '0');

    return TripSheetScaffold(
      mapFraction: 0.52,
      map: (top, bottom) => AlongRoutePreview(
        key: const Key('requesting_map'),
        pickup: lngLat(trip.board.location),
        drop: lngLat(trip.alight.location),
        from: trip.board.name,
        to: trip.alight.name,
        pulse: !state.accepted && !state.expired,
        semanticLabel: l10n.requestingFinding(mode),
        topInset: top,
        bottomInset: bottom,
      ),
      footer: AlongButton(
        key: const Key('requesting_cancel'),
        label: l10n.requestingCancel,
        variant: AlongButtonVariant.secondary,
        onPressed: state.expired || state.accepted
            ? null
            : () => ref
                  .read(requestingControllerFamilyProvider(args).notifier)
                  .cancel(),
      ),
      children: [
        Row(
          children: [
            TripModeTile(modeCode: trip.modeCode),
            const SizedBox(width: AlongSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.requestingFinding(mode),
                    style: AlongType.title(palette),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.requestingSeenNear(trip.board.name),
                    style: AlongType.caption(palette),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AlongSpace.s12),
            Semantics(
              label: l10n.requestingCountdown(state.remainingSeconds),
              excludeSemantics: true,
              child: Text(
                '$m:$s',
                key: const Key('requesting_countdown'),
                style: AlongType.numeric(palette),
              ),
            ),
          ],
        ),
        const SizedBox(height: AlongSpace.s16),
        _CountdownBar(fraction: fraction),
        if (state.cascadeMessage) ...[
          const SizedBox(height: AlongSpace.s12),
          TripNotice(
            icon: AlongIcons.search,
            text: l10n.requestingFindingAnother,
          ),
        ],
        if (state.expired) ...[
          const SizedBox(height: AlongSpace.s12),
          TripNotice(
            icon: AlongIcons.info,
            text: l10n.requestingExpired,
            warn: true,
          ),
        ],
        const SizedBox(height: AlongSpace.s16),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.requestingFare,
                style: AlongType.bodyMuted(palette),
              ),
            ),
            Text(
              formatAppMoney(ref, trip.fare.total),
              style: AlongType.title(palette),
            ),
          ],
        ),
      ],
    );
  }

  void _returnToOptions() {
    final preserved = _preservedPlan;
    if (preserved != null) {
      ref
          .read(tripOptionsControllerProvider.notifier)
          .preservePlanFrom(preserved);
    }
    if (mounted) context.go(AppRoutes.tripOptions);
  }
}

class _CountdownBar extends StatelessWidget {
  const _CountdownBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return SizedBox(
      height: 6,
      child: DecoratedBox(
        decoration: AlongCraft.compactFill(p.recessed, 6, corner: 3),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction.clamp(0.0, 1.0)),
            duration: AlongMoves.select.of(context),
            curve: AlongMoves.select.curve,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: DecoratedBox(
                decoration: AlongCraft.compactFill(p.ink, 6, corner: 3),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

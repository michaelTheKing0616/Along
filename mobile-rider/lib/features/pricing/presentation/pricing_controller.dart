import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_helpers.dart';
import 'package:mobile_rider/features/pricing/domain/pricing_route_args.dart';

class PricingState {
  const PricingState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.view,
    this.proposedNaira,
    this.terminal = PricingTerminalKind.none,
    this.errorMessage,
    this.agreedTrip,
    this.lastRiderNaira,
    this.lastDriverNaira,
    this.countdownSeconds = 0,
    this.countdownTotal = 1,
    this.driverResponseNaira,
  });

  final bool isLoading;
  final bool isSubmitting;
  final NegotiationView? view;
  final int? proposedNaira;
  final PricingTerminalKind terminal;
  final String? errorMessage;
  final TripSummary? agreedTrip;
  final int? lastRiderNaira;
  final int? lastDriverNaira;
  final int countdownSeconds;
  final int countdownTotal;
  final int? driverResponseNaira;

  bool get isTerminal => terminal != PricingTerminalKind.none;

  int get displayNaira => proposedNaira ?? view?.amountNaira ?? 0;

  int? get splitNaira {
    final v = view;
    if (v == null || !v.isOpen || !v.atCap) return null;
    return splitPreviewNaira(
      lastRiderNaira: lastRiderNaira,
      lastDriverNaira: lastDriverNaira ?? moneyToNaira(v.amount),
      anchorNaira: v.anchorNaira,
    );
  }

  PricingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    NegotiationView? view,
    int? proposedNaira,
    PricingTerminalKind? terminal,
    String? errorMessage,
    TripSummary? agreedTrip,
    int? lastRiderNaira,
    int? lastDriverNaira,
    int? countdownSeconds,
    int? countdownTotal,
    int? driverResponseNaira,
    bool clearProposed = false,
    bool clearError = false,
    bool clearAgreedTrip = false,
  }) {
    return PricingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      view: view ?? this.view,
      proposedNaira: clearProposed ? null : (proposedNaira ?? this.proposedNaira),
      terminal: terminal ?? this.terminal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      agreedTrip: clearAgreedTrip ? null : (agreedTrip ?? this.agreedTrip),
      lastRiderNaira: lastRiderNaira ?? this.lastRiderNaira,
      lastDriverNaira: lastDriverNaira ?? this.lastDriverNaira,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      countdownTotal: countdownTotal ?? this.countdownTotal,
      driverResponseNaira: driverResponseNaira ?? this.driverResponseNaira,
    );
  }
}

final pricingControllerFamilyProvider = NotifierProvider.family<
    PricingController, PricingState, PricingRouteArgs>(
  PricingController.new,
);

class PricingController extends FamilyNotifier<PricingState, PricingRouteArgs> {
  StreamSubscription<Map<String, dynamic>>? _broadcastSub;
  Timer? _countdownTimer;
  NegotiationChannel? _channel;

  @override
  PricingState build(PricingRouteArgs args) {
    ref.onDispose(() {
      _broadcastSub?.cancel();
      _countdownTimer?.cancel();
      unawaited(_channel?.unsubscribe());
    });
    Future.microtask(() => _open(args));
    return const PricingState();
  }

  Future<void> _open(PricingRouteArgs args) async {
    try {
      final repo = ref.read(negotiationRepositoryProvider);
      final view = await repo.openNegotiation(
        context: args.context,
        from: args.from,
        to: args.to,
        clientRef: args.clientRef,
        candidateToken: args.candidateToken,
        driverId: args.driverId,
      );
      _channel = ref.read(negotiationChannelProvider);
      await _channel!.subscribe(view.negotiationId);
      _broadcastSub ??= _channel!.roundUpdates.listen(_onBroadcast);

      state = state.copyWith(
        isLoading: false,
        view: view,
        proposedNaira: view.amountNaira,
        lastRiderNaira: view.proposedBy == 'rider' ? view.amountNaira : view.anchorNaira,
        clearError: true,
      );
      _syncCountdown(view);
      _startCountdownTicker();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final view = state.view;
      if (view == null || !view.isOpen) return;
      final remaining = _secondsUntil(view.expiresAt);
      if (remaining <= 0) {
        state = state.copyWith(
          terminal: PricingTerminalKind.lapsedTimeout,
          countdownSeconds: 0,
        );
        _countdownTimer?.cancel();
        return;
      }
      state = state.copyWith(countdownSeconds: remaining);
    });
  }

  void _syncCountdown(NegotiationView view) {
    final remaining = _secondsUntil(view.expiresAt);
    final total = view.roundTimeoutS * (view.roundCap + 1);
    state = state.copyWith(
      countdownSeconds: remaining.clamp(0, total),
      countdownTotal: total.clamp(view.roundTimeoutS, total),
    );
  }

  int _secondsUntil(DateTime expiresAt) {
    final now = ref.read(clockProvider).now();
    return expiresAt.difference(now).inSeconds;
  }

  void _onBroadcast(Map<String, dynamic> payload) {
    final view = state.view;
    if (view == null) return;

    final status = payload['status'] as String?;
    final amountRaw = payload['amount'];
    final proposedBy = payload['proposed_by'] as String?;
    final expiresAtRaw = payload['expires_at'] as String?;
    final round = payload['round'];

    if (status == 'lapsed') {
      final remaining = _secondsUntil(view.expiresAt);
      state = state.copyWith(
        terminal: remaining > 0
            ? PricingTerminalKind.lapsedOutOfRange
            : PricingTerminalKind.lapsedTimeout,
        view: view.copyWithStatus('lapsed'),
      );
      _countdownTimer?.cancel();
      return;
    }

    if (status == 'declined') {
      state = state.copyWith(
        terminal: PricingTerminalKind.declined,
        view: view.copyWithStatus('declined'),
      );
      _countdownTimer?.cancel();
      return;
    }

    if (status == 'agreed') {
      _countdownTimer?.cancel();
      return;
    }

    if (amountRaw == null) return;

    final amountNaira = _parseAmountNaira(amountRaw, currency: view.amount.currency);
    final nextView = view.copyWithPartial(
      round: round is num ? round.toInt() : view.round,
      amountNaira: amountNaira,
      proposedBy: proposedBy ?? view.proposedBy,
      expiresAt: expiresAtRaw == null
          ? view.expiresAt
          : DateTime.parse(expiresAtRaw).toUtc(),
    );

    var lastRider = state.lastRiderNaira;
    var lastDriver = state.lastDriverNaira;
    if (proposedBy == 'rider') {
      lastRider = amountNaira;
    } else if (proposedBy == 'driver') {
      lastDriver = amountNaira;
    }

    state = state.copyWith(
      view: nextView,
      proposedNaira: amountNaira,
      lastRiderNaira: lastRider,
      lastDriverNaira: lastDriver,
      driverResponseNaira: proposedBy == 'driver' ? amountNaira : state.driverResponseNaira,
      clearProposed: false,
    );
    _syncCountdown(nextView);
  }

  int _parseAmountNaira(Object raw, {String currency = 'NGN'}) {
    if (raw is num) return raw.round();
    if (raw is String) {
      return Money.parse(raw, currency: currency).amount.round().toBigInt().toInt();
    }
    if (raw is Map<String, dynamic>) {
      final resolved = raw['currency'] as String? ?? currency;
      return Money.parse(raw['amount'] as String, currency: resolved)
          .amount
          .round()
          .toBigInt()
          .toInt();
    }
    return state.displayNaira;
  }

  void applyChipStep(int stepNaira) {
    final base = state.displayNaira;
    state = state.copyWith(proposedNaira: base + stepNaira);
  }

  Future<void> offer() async {
    final view = state.view;
    if (view == null || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await ref.read(negotiationRepositoryProvider).negotiationRound(
            negotiationId: view.negotiationId,
            action: 'counter',
            amount: Money.fromMinorUnits(
              state.displayNaira * 100,
              currency: view.amount.currency,
            ),
          );
      _applyServerView(updated);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> accept() async {
    final view = state.view;
    if (view == null || state.isSubmitting) return;

    if (view.context == 'roaming' &&
        view.etaBand == 'none' &&
        ref.read(pricingRouteArgsProvider)?.hailIntent != null) {
      await _hailAfterNoneBandAccept();
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await ref.read(negotiationRepositoryProvider).negotiationRound(
            negotiationId: view.negotiationId,
            action: 'accept',
          );
      await _handleAgreed(updated);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> _hailAfterNoneBandAccept() async {
    final args = ref.read(pricingRouteArgsProvider);
    final hail = args?.hailIntent;
    if (hail == null) {
      await accept();
      return;
    }
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final trip = await ref.read(negotiationRepositoryProvider).hailRoaming(
            candidateToken: hail.candidateToken,
            destination: args!.to,
            clientRef: args.clientRef,
          );
      state = state.copyWith(
        isSubmitting: false,
        agreedTrip: trip,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> splitDifference() async {
    final view = state.view;
    if (view == null || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated =
          await ref.read(negotiationRepositoryProvider).negotiationSplit(
                view.negotiationId,
              );
      _applyServerView(updated);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> skip() async {
    final view = state.view;
    if (view == null || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await ref.read(negotiationRepositoryProvider).negotiationRound(
            negotiationId: view.negotiationId,
            action: 'decline',
          );
      state = state.copyWith(
        isSubmitting: false,
        terminal: PricingTerminalKind.declined,
        view: updated,
      );
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> _handleAgreed(NegotiationView updated) async {
    if (updated.trip != null) {
      final trip = DomainMappers.tripFromDto(updated.trip!);
      state = state.copyWith(
        isSubmitting: false,
        view: updated,
        agreedTrip: trip,
      );
      return;
    }
    state = state.copyWith(isSubmitting: false, view: updated);
  }

  void _applyServerView(NegotiationView updated) {
    var lastRider = state.lastRiderNaira;
    var lastDriver = state.lastDriverNaira;
    if (updated.proposedBy == 'rider') {
      lastRider = updated.amountNaira;
    } else if (updated.proposedBy == 'driver') {
      lastDriver = updated.amountNaira;
    } else if (updated.proposedBy == 'system') {
      // Split round — keep both sides for display.
    }

    state = state.copyWith(
      isSubmitting: false,
      view: updated,
      proposedNaira: updated.amountNaira,
      lastRiderNaira: lastRider,
      lastDriverNaira: lastDriver,
      driverResponseNaira:
          updated.proposedBy == 'driver' ? updated.amountNaira : state.driverResponseNaira,
    );
    _syncCountdown(updated);

    if (updated.isAgreed && updated.trip != null) {
      unawaited(_handleAgreed(updated));
    }
  }

  /// Cancels countdown ticker — used by widget tests to avoid pending timers.
  void disposeCountdown() => _countdownTimer?.cancel();

  /// Test hook — inject terminal state without backend.
  void setTerminalForTest(PricingTerminalKind terminal) {
    _countdownTimer?.cancel();
    state = state.copyWith(terminal: terminal);
  }

  /// Test hook — seed an open view without RPC.
  void seedViewForTest(NegotiationView view) {
    state = state.copyWith(
      isLoading: false,
      view: view,
      proposedNaira: view.amountNaira,
      lastRiderNaira: view.amountNaira,
    );
    _syncCountdown(view);
  }
}

/// Holds current route args for hail fallback inside controller.
final pricingRouteArgsProvider = StateProvider<PricingRouteArgs?>((ref) => null);

extension on NegotiationView {
  NegotiationView copyWithStatus(String status) => NegotiationView(
        negotiationId: negotiationId,
        status: status,
        context: context,
        anchor: anchor,
        agreedAmount: agreedAmount,
        roundCap: roundCap,
        roundTimeoutS: roundTimeoutS,
        etaBand: etaBand,
        expiresAt: expiresAt,
        round: round,
        amount: amount,
        proposedBy: proposedBy,
        chipSteps: chipSteps,
        trip: trip,
      );

  NegotiationView copyWithPartial({
    int? round,
    int? amountNaira,
    String? proposedBy,
    DateTime? expiresAt,
  }) =>
      NegotiationView(
        negotiationId: negotiationId,
        status: status,
        context: context,
        anchor: anchor,
        agreedAmount: agreedAmount,
        roundCap: roundCap,
        roundTimeoutS: roundTimeoutS,
        etaBand: etaBand,
        expiresAt: expiresAt ?? this.expiresAt,
        round: round ?? this.round,
        amount: Money.fromMinorUnits((amountNaira ?? this.amountNaira) * 100, currency: amount.currency),
        proposedBy: proposedBy ?? this.proposedBy,
        chipSteps: chipSteps,
        trip: trip,
      );
}

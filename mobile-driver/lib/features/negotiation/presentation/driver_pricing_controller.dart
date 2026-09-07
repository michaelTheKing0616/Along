import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_realtime/along_realtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/negotiation/domain/pricing_helpers.dart';
import 'package:mobile_driver/features/home/presentation/home_controller.dart';

class DriverPricingState {
  const DriverPricingState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.view,
    this.proposedNaira,
    this.terminal = DriverPricingTerminalKind.none,
    this.errorMessage,
    this.lastRiderNaira,
    this.lastDriverNaira,
    this.countdownSeconds = 0,
    this.countdownTotal = 1,
  });

  final bool isLoading;
  final bool isSubmitting;
  final NegotiationView? view;
  final int? proposedNaira;
  final DriverPricingTerminalKind terminal;
  final String? errorMessage;
  final int? lastRiderNaira;
  final int? lastDriverNaira;
  final int countdownSeconds;
  final int countdownTotal;

  bool get isTerminal => terminal != DriverPricingTerminalKind.none;
  bool get isVisible => view != null && !isTerminal;

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

  DriverPricingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    NegotiationView? view,
    int? proposedNaira,
    DriverPricingTerminalKind? terminal,
    String? errorMessage,
    int? lastRiderNaira,
    int? lastDriverNaira,
    int? countdownSeconds,
    int? countdownTotal,
    bool clearProposed = false,
    bool clearError = false,
    bool clearView = false,
  }) {
    return DriverPricingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      view: clearView ? null : (view ?? this.view),
      proposedNaira: clearProposed ? null : (proposedNaira ?? this.proposedNaira),
      terminal: terminal ?? this.terminal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastRiderNaira: lastRiderNaira ?? this.lastRiderNaira,
      lastDriverNaira: lastDriverNaira ?? this.lastDriverNaira,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      countdownTotal: countdownTotal ?? this.countdownTotal,
    );
  }
}

class DriverPricingNotifier extends Notifier<DriverPricingState> {
  StreamSubscription<Map<String, dynamic>>? _broadcastSub;
  Timer? _pollTimer;
  Timer? _countdownTimer;
  NegotiationChannel? _channel;
  String? _activeNegotiationId;

  @override
  DriverPricingState build() {
    ref.onDispose(_teardown);
    ref.listen(driverHomeControllerProvider, (previous, next) {
      if (next.isOnline) {
        unawaited(_startPolling());
      } else {
        _stopPolling();
        state = const DriverPricingState();
      }
    });
    Future.microtask(_bootstrap);
    return const DriverPricingState();
  }

  Future<void> _bootstrap() async {
    final home = ref.read(driverHomeControllerProvider);
    if (home.isOnline) {
      await _startPolling();
    }
  }

  Future<void> _startPolling() async {
    _pollTimer?.cancel();
    final home = ref.read(driverHomeControllerProvider);
    if (!home.isOnline) return;

    final pollS = (await ref.read(configRepositoryProvider).configNum(
          'driver.negotiation_poll_s',
          cityId: home.cityId,
        ))
        .round()
        .clamp(1, 30);

    await _pollOnce();
    _pollTimer = Timer.periodic(Duration(seconds: pollS), (_) {
      unawaited(_pollOnce());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _broadcastSub?.cancel();
    _broadcastSub = null;
    unawaited(_channel?.unsubscribe());
    _channel = null;
    _activeNegotiationId = null;
  }

  Future<void> _pollOnce() async {
    if (state.isSubmitting || state.isTerminal) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final home = ref.read(driverHomeControllerProvider);
    if (!home.isOnline) return;

    try {
      final view = await ref.read(negotiationRepositoryProvider).fetchLatestOpenNegotiationForDriver(
            driverId: user.id,
            config: ref.read(configRepositoryProvider),
            cityId: home.cityId,
          );

      if (view == null) {
        if (_activeNegotiationId != null) {
          _stopPolling();
          state = const DriverPricingState();
          unawaited(_startPolling());
        }
        return;
      }

      if (_activeNegotiationId != view.negotiationId) {
        await _subscribe(view.negotiationId);
        _activeNegotiationId = view.negotiationId;
      }

      state = state.copyWith(
        isLoading: false,
        view: view,
        proposedNaira: view.amountNaira,
        lastRiderNaira: view.proposedBy == 'rider'
            ? view.amountNaira
            : state.lastRiderNaira ?? view.anchorNaira,
        lastDriverNaira:
            view.proposedBy == 'driver' ? view.amountNaira : state.lastDriverNaira,
        clearError: true,
      );
      _syncCountdown(view);
      _startCountdownTicker();
    } catch (_) {
      // Poll failures are best-effort; Realtime remains primary after subscribe.
    }
  }

  Future<void> _subscribe(String negotiationId) async {
    _broadcastSub?.cancel();
    await _channel?.unsubscribe();
    _channel = ref.read(negotiationChannelProvider);
    await _channel!.subscribe(negotiationId);
    _broadcastSub = _channel!.roundUpdates.listen(_onBroadcast);
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final view = state.view;
      if (view == null || !view.isOpen) return;
      final remaining = _secondsUntil(view.expiresAt);
      if (remaining <= 0) {
        state = state.copyWith(
          terminal: DriverPricingTerminalKind.lapsedTimeout,
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
            ? DriverPricingTerminalKind.lapsedOutOfRange
            : DriverPricingTerminalKind.lapsedTimeout,
      );
      _countdownTimer?.cancel();
      return;
    }

    if (status == 'declined') {
      state = state.copyWith(terminal: DriverPricingTerminalKind.declined);
      _countdownTimer?.cancel();
      return;
    }

    if (status == 'agreed') {
      _countdownTimer?.cancel();
      state = const DriverPricingState();
      _activeNegotiationId = null;
      return;
    }

    if (amountRaw == null) return;

    final amountNaira = _parseAmountNaira(amountRaw, currency: view.amount.currency);
    final nextView = _copyView(
      view,
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
      return Money.parse(
        raw['amount'] as String,
        currency: resolved,
      ).amount.round().toBigInt().toInt();
    }
    return state.displayNaira;
  }

  void applyChipStep(int stepNaira) {
    final base = state.displayNaira;
    state = state.copyWith(proposedNaira: base + stepNaira);
  }

  Future<void> offer() async {
    final view = state.view;
    if (view == null || state.isSubmitting || view.proposedBy == 'driver') return;
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
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
    }
  }

  Future<void> accept() async {
    final view = state.view;
    if (view == null || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await ref.read(negotiationRepositoryProvider).negotiationRound(
            negotiationId: view.negotiationId,
            action: 'accept',
          );
      if (updated.isAgreed) {
        state = const DriverPricingState();
        _activeNegotiationId = null;
        return;
      }
      _applyServerView(updated);
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
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
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
    }
  }

  Future<void> skip() async {
    final view = state.view;
    if (view == null || state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(negotiationRepositoryProvider).negotiationRound(
            negotiationId: view.negotiationId,
            action: 'decline',
          );
      state = state.copyWith(
        isSubmitting: false,
        terminal: DriverPricingTerminalKind.declined,
      );
    } catch (_) {
      state = state.copyWith(isSubmitting: false, errorMessage: 'generic');
    }
  }

  void _applyServerView(NegotiationView updated) {
    var lastRider = state.lastRiderNaira;
    var lastDriver = state.lastDriverNaira;
    if (updated.proposedBy == 'rider') {
      lastRider = updated.amountNaira;
    } else if (updated.proposedBy == 'driver') {
      lastDriver = updated.amountNaira;
    }

    state = state.copyWith(
      isSubmitting: false,
      view: updated,
      proposedNaira: updated.amountNaira,
      lastRiderNaira: lastRider,
      lastDriverNaira: lastDriver,
    );
    _syncCountdown(updated);

    if (updated.isAgreed) {
      state = const DriverPricingState();
      _activeNegotiationId = null;
    }
  }

  void dismissTerminal() {
    state = const DriverPricingState();
    _activeNegotiationId = null;
  }

  void seedViewForTest(NegotiationView view) {
    state = state.copyWith(
      isLoading: false,
      view: view,
      proposedNaira: view.amountNaira,
      lastRiderNaira: view.amountNaira,
    );
    _syncCountdown(view);
  }

  void _teardown() {
    _stopPolling();
  }

  NegotiationView _copyView(
    NegotiationView view, {
    int? round,
    int? amountNaira,
    String? proposedBy,
    DateTime? expiresAt,
  }) =>
      NegotiationView(
        negotiationId: view.negotiationId,
        status: view.status,
        context: view.context,
        anchor: view.anchor,
        agreedAmount: view.agreedAmount,
        roundCap: view.roundCap,
        roundTimeoutS: view.roundTimeoutS,
        etaBand: view.etaBand,
        expiresAt: expiresAt ?? view.expiresAt,
        round: round ?? view.round,
        amount: Money.fromMinorUnits(
          (amountNaira ?? view.amountNaira) * 100,
          currency: view.amount.currency,
        ),
        proposedBy: proposedBy ?? view.proposedBy,
        chipSteps: view.chipSteps,
        trip: view.trip,
      );
}

final driverPricingNotifierProvider =
    NotifierProvider<DriverPricingNotifier, DriverPricingState>(
  DriverPricingNotifier.new,
);

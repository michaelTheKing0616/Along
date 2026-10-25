import 'package:along_core/along_core.dart' as core;
import 'package:along_data/along_data.dart' hide Money;
import 'package:along_design/along_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';

class DriverLedgerSnapshot {
  const DriverLedgerSnapshot({
    required this.balance,
    required this.blockThreshold,
    required this.standing,
    required this.standingLabel,
    required this.cardState,
    this.graceDeadline,
    this.depositHeld,
    this.isLoading = false,
  });

  final core.Money balance;
  final core.Money blockThreshold;
  final String standing;
  final String standingLabel;
  final BalanceCardState cardState;
  final DateTime? graceDeadline;
  final core.Money? depositHeld;
  final bool isLoading;

  bool get isLedgerBlocked =>
      standing == 'matching_paused' || balance.compareTo(blockThreshold) <= 0;

  DriverLedgerSnapshot copyWith({
    core.Money? balance,
    core.Money? blockThreshold,
    String? standing,
    String? standingLabel,
    BalanceCardState? cardState,
    DateTime? graceDeadline,
    core.Money? depositHeld,
    bool? isLoading,
  }) {
    return DriverLedgerSnapshot(
      balance: balance ?? this.balance,
      blockThreshold: blockThreshold ?? this.blockThreshold,
      standing: standing ?? this.standing,
      standingLabel: standingLabel ?? this.standingLabel,
      cardState: cardState ?? this.cardState,
      graceDeadline: graceDeadline ?? this.graceDeadline,
      depositHeld: depositHeld ?? this.depositHeld,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static DriverLedgerSnapshot initial() => DriverLedgerSnapshot(
    balance: core.Money.zero(),
    blockThreshold: core.Money.parse('-5000.00', currency: 'NGN'),
    standing: 'good_standing',
    standingLabel: core.standingLabel('good_standing'),
    cardState: BalanceCardState.good,
  );
}

final driverLedgerControllerProvider =
    NotifierProvider<DriverLedgerController, DriverLedgerSnapshot>(
      DriverLedgerController.new,
    );

class DriverLedgerController extends Notifier<DriverLedgerSnapshot> {
  @override
  DriverLedgerSnapshot build() {
    Future.microtask(refresh);
    return DriverLedgerSnapshot.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(ledgerRepositoryProvider).driverBalance();
      final balance = DomainMappers.moneyFromDto(response.balance);
      final threshold = DomainMappers.moneyFromDto(response.block_threshold);
      final standing = response.standing;
      final cardState = _cardStateFor(standing, balance, threshold);
      state = DriverLedgerSnapshot(
        balance: balance,
        blockThreshold: threshold,
        standing: standing,
        standingLabel: core.standingLabel(standing),
        cardState: cardState,
        graceDeadline: response.grace_deadline != null
            ? DateTime.parse(response.grace_deadline!)
            : null,
        depositHeld: DomainMappers.moneyFromDto(response.deposit_held),
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  BalanceCardState _cardStateFor(
    String standing,
    core.Money balance,
    core.Money threshold,
  ) {
    if (standing == 'matching_paused' || balance.compareTo(threshold) <= 0) {
      return BalanceCardState.paused;
    }
    if (standing == 'warned') {
      return BalanceCardState.warned;
    }
    return BalanceCardState.good;
  }
}

final earningsLedgerPageProvider =
    FutureProvider.autoDispose<core.DriverLedgerPage>((ref) async {
      return ref.read(ledgerRepositoryProvider).driverLedger(limit: 50);
    });

final earningsCashTripsProvider =
    FutureProvider.autoDispose<List<TripCashSummary>>((ref) async {
      return ref.read(ledgerRepositoryProvider).recentCashTrips(days: 7);
    });

final earningsContextProvider =
    FutureProvider.autoDispose<DriverEarningsContext>((ref) async {
      return ref.read(ledgerRepositoryProvider).earningsContext(days: 7);
    });

final standingHistoryProvider =
    FutureProvider.autoDispose<List<StandingTransitionEntry>>((ref) async {
      return ref.read(ledgerRepositoryProvider).standingHistory();
    });

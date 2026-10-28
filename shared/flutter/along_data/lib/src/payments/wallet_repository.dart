/// One line in the rider's Along credit history.
enum WalletEntryKind { topUp, fare, refund }

class WalletEntry {
  const WalletEntry({
    required this.kind,
    required this.amount,
    required this.at,
  });

  final WalletEntryKind kind;

  /// Whole naira. Positive adds credit, negative is spent.
  final int amount;
  final DateTime at;
}

class WalletSummary {
  const WalletSummary({required this.balance, this.entries = const []});

  /// Whole naira.
  final int balance;

  /// Newest first.
  final List<WalletEntry> entries;
}

/// Along credit. Top ups carry a client key so a retry never charges twice.
abstract class WalletRepository {
  Future<WalletSummary> fetch();

  Future<WalletSummary> topUp({
    required int amount,
    required String idempotencyKey,
  });
}

/// Smallest and largest top up the app offers, in naira.
const walletTopUpMin = 100;
const walletTopUpMax = 50000;

/// Returns an error key for a custom amount, or null when it is valid.
String? validateTopUpAmount(int? amount) {
  if (amount == null) return 'empty';
  if (amount < walletTopUpMin) return 'tooSmall';
  if (amount > walletTopUpMax) return 'tooLarge';
  return null;
}

/// In-memory wallet for tests and demos. Repeating a key is a no-op.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({
    WalletSummary initial = const WalletSummary(balance: 0),
    this.fail = false,
    DateTime Function()? now,
  }) : _summary = initial,
       _now = now ?? DateTime.now;

  WalletSummary _summary;
  bool fail;
  final DateTime Function() _now;
  final _seen = <String>{};

  @override
  Future<WalletSummary> fetch() async {
    if (fail) throw StateError('wallet unavailable');
    return _summary;
  }

  @override
  Future<WalletSummary> topUp({
    required int amount,
    required String idempotencyKey,
  }) async {
    if (fail) throw StateError('wallet unavailable');
    if (_seen.add(idempotencyKey)) {
      _summary = WalletSummary(
        balance: _summary.balance + amount,
        entries: [
          WalletEntry(kind: WalletEntryKind.topUp, amount: amount, at: _now()),
          ..._summary.entries,
        ],
      );
    }
    return _summary;
  }
}

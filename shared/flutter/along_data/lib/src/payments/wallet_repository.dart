import 'package:along_data/src/supabase/along_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

/// One line in the rider's Along credit history.
enum WalletEntryKind { topUp, fare, refund, send, pass, split }

class WalletEntry {
  const WalletEntry({
    required this.kind,
    required this.amount,
    required this.at,
    this.counterparty,
  });

  final WalletEntryKind kind;

  /// Whole naira. Positive adds credit, negative is spent.
  final int amount;
  final DateTime at;

  /// The other rider on a send or split, when there is one.
  final String? counterparty;
}

/// A co-rider asked this rider to pay their share of a fare.
class WalletSplitRequest {
  const WalletSplitRequest({
    required this.id,
    required this.amount,
    required this.requesterName,
  });

  final String id;
  final int amount;
  final String requesterName;
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    this.entries = const [],
    this.splitsOwed = const [],
  });

  /// Whole naira.
  final int balance;

  /// Newest first.
  final List<WalletEntry> entries;

  /// Pending requests this rider can pay or decline.
  final List<WalletSplitRequest> splitsOwed;
}

/// Why a wallet call failed, so the screen can say what to do next.
enum WalletFailure { insufficientFunds, notFound, invalid, unavailable }

class WalletException implements Exception {
  const WalletException(this.failure);

  final WalletFailure failure;

  @override
  String toString() => 'WalletException($failure)';
}

/// Along credit. Every write carries a client key so a retry never moves
/// money twice; the server replays the first result for a repeated key.
abstract class WalletRepository {
  Future<WalletSummary> fetch();

  Future<void> topUp({required int amount, required String idempotencyKey});

  Future<void> send({
    required String phone,
    required int amount,
    required String idempotencyKey,
  });

  Future<void> buyPass({required String idempotencyKey});

  /// Asks each co-rider for [share]. Returns how many requests went out.
  Future<int> requestSplit({
    required List<String> phones,
    required int share,
    required String idempotencyKey,
  });

  Future<void> settleSplit({
    required String splitId,
    required bool accept,
    required String idempotencyKey,
  });
}

/// Smallest and largest top up the app offers, in naira.
const walletTopUpMin = 100;
const walletTopUpMax = 50000;

/// Smallest send or split share, in naira.
const walletSendMin = 50;

/// Monthly Along Pass price, in naira. Matches `wallet_buy_pass`.
const walletPassPrice = 2000;

/// Returns an error key for a custom amount, or null when it is valid.
String? validateTopUpAmount(int? amount) {
  if (amount == null) return 'empty';
  if (amount < walletTopUpMin) return 'tooSmall';
  if (amount > walletTopUpMax) return 'tooLarge';
  return null;
}

/// Returns an error key for a send amount against the balance, or null.
String? validateSendAmount(int? amount, int balance) {
  if (amount == null) return 'empty';
  if (amount < walletSendMin) return 'tooSmall';
  if (amount > walletTopUpMax) return 'tooLarge';
  if (amount > balance) return 'insufficient';
  return null;
}

/// Normalises a Nigerian number to E.164 (+234…), or null when it is not one.
String? normaliseNgPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (RegExp(r'^\+234[789][01]\d{8}$').hasMatch(digits)) return digits;
  if (RegExp(r'^234[789][01]\d{8}$').hasMatch(digits)) return '+$digits';
  if (RegExp(r'^0[789][01]\d{8}$').hasMatch(digits)) {
    return '+234${digits.substring(1)}';
  }
  return null;
}

/// Equal shares of [total] across [people], rounded up to the naira so the
/// requester is never short. The requester pays the remainder.
List<int> splitShares(int total, int people) {
  if (people <= 0 || total <= 0) return const [];
  final share = (total / people).ceil();
  final mine = total - share * (people - 1);
  return [mine, for (var i = 1; i < people; i++) share];
}

/// Supabase-backed wallet over the `get_wallet` / `wallet_*` RPCs.
class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository(this._gateway);

  final AlongSupabase _gateway;

  Future<dynamic> _call(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await _gateway.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw WalletException(walletFailureFor(e.message));
    } on WalletException {
      rethrow;
    } catch (_) {
      throw const WalletException(WalletFailure.unavailable);
    }
  }

  @override
  Future<WalletSummary> fetch() async =>
      parseWalletSummary(await _call('get_wallet'));

  @override
  Future<void> topUp({required int amount, required String idempotencyKey}) =>
      _call('wallet_top_up', {
        'p_amount': amount,
        'p_idempotency_key': idempotencyKey,
      });

  @override
  Future<void> send({
    required String phone,
    required int amount,
    required String idempotencyKey,
  }) => _call('wallet_send', {
    'p_to_phone': phone,
    'p_amount': amount,
    'p_idempotency_key': idempotencyKey,
  });

  @override
  Future<void> buyPass({required String idempotencyKey}) =>
      _call('wallet_buy_pass', {'p_idempotency_key': idempotencyKey});

  @override
  Future<int> requestSplit({
    required List<String> phones,
    required int share,
    required String idempotencyKey,
  }) async {
    final res = await _call('wallet_request_split', {
      'p_phones': phones,
      'p_share': share,
      'p_trip_id': null,
      'p_idempotency_key': idempotencyKey,
    });
    final ids = res is Map ? res['split_ids'] : null;
    return ids is List ? ids.length : 0;
  }

  @override
  Future<void> settleSplit({
    required String splitId,
    required bool accept,
    required String idempotencyKey,
  }) => _call('wallet_settle_split', {
    'p_split_id': splitId,
    'p_accept': accept,
    'p_idempotency_key': idempotencyKey,
  });
}

/// Maps a server error message (`raise exception 'CODE'`) to a failure.
WalletFailure walletFailureFor(String message) {
  if (message.contains('INSUFFICIENT_FUNDS')) {
    return WalletFailure.insufficientFunds;
  }
  if (message.contains('NOT_FOUND')) return WalletFailure.notFound;
  if (message.contains('VALIDATION') ||
      message.contains('FORBIDDEN') ||
      message.contains('CONFLICT')) {
    return WalletFailure.invalid;
  }
  return WalletFailure.unavailable;
}

int _naira(Object? v) =>
    v is num ? v.round() : num.tryParse('$v')?.round() ?? 0;

/// Parses the `get_wallet` payload.
WalletSummary parseWalletSummary(Object? raw) {
  if (raw is! Map) throw const WalletException(WalletFailure.unavailable);
  final entries = <WalletEntry>[];
  for (final e in (raw['entries'] as List?) ?? const []) {
    if (e is! Map) continue;
    final amount = _naira(e['amount']);
    final memo = e['memo'] is Map
        ? e['memo'] as Map
        : const <String, Object?>{};
    final kind = switch (e['kind']) {
      'top_up' => WalletEntryKind.topUp,
      'refund' => WalletEntryKind.refund,
      'send' => WalletEntryKind.send,
      'pass' => WalletEntryKind.pass,
      'split' => WalletEntryKind.split,
      _ => WalletEntryKind.fare,
    };
    final other = amount < 0 ? memo['to'] : memo['from'];
    entries.add(
      WalletEntry(
        kind: kind,
        amount: amount,
        at:
            DateTime.tryParse('${e['created_at']}')?.toLocal() ??
            DateTime(2000),
        counterparty: other is String && other.isNotEmpty ? other : null,
      ),
    );
  }
  return WalletSummary(
    balance: _naira(raw['balance']),
    entries: entries,
    splitsOwed: [
      for (final s in (raw['splits_owed'] as List?) ?? const [])
        if (s is Map)
          WalletSplitRequest(
            id: '${s['id']}',
            amount: _naira(s['amount']),
            requesterName: '${s['requester_name'] ?? ''}',
          ),
    ],
  );
}

/// In-memory wallet for tests and demos. Mirrors the server rules: repeated
/// keys are no-ops and the balance never goes negative.
class FakeWalletRepository implements WalletRepository {
  FakeWalletRepository({
    WalletSummary initial = const WalletSummary(balance: 0),
    this.fail = false,
    this.knownPhones = const {},
    DateTime Function()? now,
  }) : _summary = initial,
       _now = now ?? DateTime.now;

  WalletSummary _summary;
  bool fail;

  /// E.164 number → display name of riders who can receive.
  final Map<String, String> knownPhones;
  final DateTime Function() _now;
  final _seen = <String>{};

  WalletSummary get summary => _summary;

  void _guard() {
    if (fail) throw const WalletException(WalletFailure.unavailable);
  }

  void _post(WalletEntryKind kind, int amount, {String? who}) {
    if (_summary.balance + amount < 0) {
      throw const WalletException(WalletFailure.insufficientFunds);
    }
    _summary = WalletSummary(
      balance: _summary.balance + amount,
      entries: [
        WalletEntry(kind: kind, amount: amount, at: _now(), counterparty: who),
        ..._summary.entries,
      ],
      splitsOwed: _summary.splitsOwed,
    );
  }

  @override
  Future<WalletSummary> fetch() async {
    _guard();
    return _summary;
  }

  @override
  Future<void> topUp({
    required int amount,
    required String idempotencyKey,
  }) async {
    _guard();
    if (validateTopUpAmount(amount) != null) {
      throw const WalletException(WalletFailure.invalid);
    }
    if (_seen.add(idempotencyKey)) _post(WalletEntryKind.topUp, amount);
  }

  @override
  Future<void> send({
    required String phone,
    required int amount,
    required String idempotencyKey,
  }) async {
    _guard();
    final who = knownPhones[phone];
    if (who == null) throw const WalletException(WalletFailure.notFound);
    if (_seen.contains(idempotencyKey)) return;
    _post(WalletEntryKind.send, -amount, who: who);
    _seen.add(idempotencyKey);
  }

  @override
  Future<void> buyPass({required String idempotencyKey}) async {
    _guard();
    if (_seen.contains(idempotencyKey)) return;
    _post(WalletEntryKind.pass, -walletPassPrice);
    _seen.add(idempotencyKey);
  }

  @override
  Future<int> requestSplit({
    required List<String> phones,
    required int share,
    required String idempotencyKey,
  }) async {
    _guard();
    if (phones.any((p) => !knownPhones.containsKey(p))) {
      throw const WalletException(WalletFailure.notFound);
    }
    _seen.add(idempotencyKey);
    return phones.length;
  }

  @override
  Future<void> settleSplit({
    required String splitId,
    required bool accept,
    required String idempotencyKey,
  }) async {
    _guard();
    final req = _summary.splitsOwed.where((s) => s.id == splitId).firstOrNull;
    if (req == null) return; // already settled: replay
    if (accept) {
      _post(WalletEntryKind.split, -req.amount, who: req.requesterName);
    }
    _summary = WalletSummary(
      balance: _summary.balance,
      entries: _summary.entries,
      splitsOwed: [
        for (final s in _summary.splitsOwed)
          if (s.id != splitId) s,
      ],
    );
  }
}

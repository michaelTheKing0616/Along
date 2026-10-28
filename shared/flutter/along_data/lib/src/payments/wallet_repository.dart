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

/// One way to buy rides ahead. Plans come from the server (`pass_plans`).
class WalletPassPlan {
  const WalletPassPlan({
    required this.id,
    required this.rides,
    required this.price,
    required this.days,
  });

  /// `week`, `pack` or `month`.
  final String id;
  final int rides;

  /// Whole naira.
  final int price;
  final int days;

  /// Whole naira per ride, rounded up.
  int get perRide => (price + rides - 1) ~/ rides;

  /// What [rides] single fares at [avgFare] would cost minus the plan price.
  /// Null when there is no fare history to compare with.
  int? savingVs(int? avgFare) =>
      avgFare == null ? null : avgFare * rides - price;
}

/// Mirrors `private.wallet_pass_plans()`; used when the server sends none.
const walletDefaultPassPlans = [
  WalletPassPlan(id: 'week', rides: 10, price: 4800, days: 7),
  WalletPassPlan(id: 'pack', rides: 5, price: 2600, days: 30),
  WalletPassPlan(id: 'month', rides: 40, price: 17000, days: 30),
];

class WalletActivePass {
  const WalletActivePass({
    required this.plan,
    required this.rides,
    required this.expiresAt,
  });

  final String plan;
  final int rides;
  final DateTime expiresAt;
}

enum WalletSplitStatus { pending, paid, declined }

/// A share this rider asked a co-rider for, with where it stands.
class WalletSplitSent {
  const WalletSplitSent({
    required this.id,
    required this.payerName,
    required this.amount,
    required this.status,
  });

  final String id;
  final String payerName;
  final int amount;
  final WalletSplitStatus status;
}

class WalletSummary {
  const WalletSummary({
    required this.balance,
    this.entries = const [],
    this.splitsOwed = const [],
    this.splitsSent = const [],
    this.passPlans = walletDefaultPassPlans,
    this.avgFare,
    this.activePass,
  });

  /// Whole naira.
  final int balance;

  /// Newest first.
  final List<WalletEntry> entries;

  /// Pending requests this rider can pay or decline.
  final List<WalletSplitRequest> splitsOwed;

  /// Newest first; the latest ten shares this rider asked for.
  final List<WalletSplitSent> splitsSent;

  final List<WalletPassPlan> passPlans;

  /// Mean of the rider's recent wallet fares, whole naira. Null with no fares.
  final int? avgFare;

  final WalletActivePass? activePass;

  WalletSummary copyWith({
    int? balance,
    List<WalletEntry>? entries,
    List<WalletSplitRequest>? splitsOwed,
    List<WalletSplitSent>? splitsSent,
    WalletActivePass? activePass,
  }) => WalletSummary(
    balance: balance ?? this.balance,
    entries: entries ?? this.entries,
    splitsOwed: splitsOwed ?? this.splitsOwed,
    splitsSent: splitsSent ?? this.splitsSent,
    passPlans: passPlans,
    avgFare: avgFare,
    activePass: activePass ?? this.activePass,
  );
}

/// Why a wallet call failed, so the screen can say what to do next.
enum WalletFailure { insufficientFunds, notFound, invalid, unavailable }

class WalletException implements Exception {
  const WalletException(this.failure, {this.detail});

  final WalletFailure failure;

  /// Server detail, e.g. the phone number that is not on Along.
  final String? detail;

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

  Future<void> buyPass({required String plan, required String idempotencyKey});

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
      throw WalletException(
        walletFailureFor(e.message),
        detail: (e.details is String && '${e.details}'.isNotEmpty)
            ? '${e.details}'
            : null,
      );
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
  Future<void> buyPass({
    required String plan,
    required String idempotencyKey,
  }) => _call('wallet_buy_pass', {
    'p_plan': plan,
    'p_idempotency_key': idempotencyKey,
  });

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
    splitsSent: [
      for (final s in (raw['splits_requested'] as List?) ?? const [])
        if (s is Map)
          WalletSplitSent(
            id: '${s['id']}',
            payerName: '${s['payer_name'] ?? ''}',
            amount: _naira(s['amount']),
            status: switch (s['status']) {
              'paid' => WalletSplitStatus.paid,
              'declined' => WalletSplitStatus.declined,
              _ => WalletSplitStatus.pending,
            },
          ),
    ],
    passPlans: _plans(raw['pass_plans']),
    avgFare: raw['avg_fare'] == null ? null : _naira(raw['avg_fare']),
    activePass: _activePass(raw['active_pass']),
  );
}

List<WalletPassPlan> _plans(Object? raw) {
  if (raw is! List || raw.isEmpty) return walletDefaultPassPlans;
  return [
    for (final p in raw)
      if (p is Map && _naira(p['rides']) > 0)
        WalletPassPlan(
          id: '${p['plan']}',
          rides: _naira(p['rides']),
          price: _naira(p['price']),
          days: _naira(p['days']),
        ),
  ];
}

WalletActivePass? _activePass(Object? raw) {
  if (raw is! Map) return null;
  final at = DateTime.tryParse('${raw['expires_at']}');
  if (at == null) return null;
  return WalletActivePass(
    plan: '${raw['plan']}',
    rides: _naira(raw['rides']),
    expiresAt: at.toLocal(),
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
    _summary = _summary.copyWith(
      balance: _summary.balance + amount,
      entries: [
        WalletEntry(kind: kind, amount: amount, at: _now(), counterparty: who),
        ..._summary.entries,
      ],
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
  Future<void> buyPass({
    required String plan,
    required String idempotencyKey,
  }) async {
    _guard();
    if (_seen.contains(idempotencyKey)) return;
    final p = _summary.passPlans.where((x) => x.id == plan).firstOrNull;
    if (p == null) throw const WalletException(WalletFailure.invalid);
    _post(WalletEntryKind.pass, -p.price);
    _summary = _summary.copyWith(
      activePass: WalletActivePass(
        plan: p.id,
        rides: p.rides,
        expiresAt: _now().add(Duration(days: p.days)),
      ),
    );
    _seen.add(idempotencyKey);
  }

  @override
  Future<int> requestSplit({
    required List<String> phones,
    required int share,
    required String idempotencyKey,
  }) async {
    _guard();
    final missing = phones.where((p) => !knownPhones.containsKey(p));
    if (missing.isNotEmpty) {
      throw WalletException(WalletFailure.notFound, detail: missing.first);
    }
    if (_seen.add(idempotencyKey)) {
      _summary = _summary.copyWith(
        splitsSent: [
          for (var i = 0; i < phones.length; i++)
            WalletSplitSent(
              id: '$idempotencyKey-$i',
              payerName: knownPhones[phones[i]]!,
              amount: share,
              status: WalletSplitStatus.pending,
            ),
          ..._summary.splitsSent,
        ],
      );
    }
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
    _summary = _summary.copyWith(
      splitsOwed: [
        for (final s in _summary.splitsOwed)
          if (s.id != splitId) s,
      ],
    );
  }
}

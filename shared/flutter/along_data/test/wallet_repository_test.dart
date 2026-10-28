import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'support/fake_along_supabase.dart';

void main() {
  group('FakeWalletRepository', () {
    test('a repeated top up key credits once', () async {
      final wallet = FakeWalletRepository(
        initial: const WalletSummary(balance: 4200),
      );
      await wallet.topUp(amount: 2000, idempotencyKey: 'k1');
      await wallet.topUp(amount: 2000, idempotencyKey: 'k1');
      expect(wallet.summary.balance, 6200);
      expect(wallet.summary.entries.single.kind, WalletEntryKind.topUp);
    });

    test('send never takes the balance below zero', () async {
      final wallet = FakeWalletRepository(
        initial: const WalletSummary(balance: 500),
        knownPhones: const {'+2348031234567': 'Ada'},
      );
      await expectLater(
        wallet.send(phone: '+2348031234567', amount: 900, idempotencyKey: 'k'),
        throwsA(
          isA<WalletException>().having(
            (e) => e.failure,
            'failure',
            WalletFailure.insufficientFunds,
          ),
        ),
      );
      expect(wallet.summary.balance, 500);
    });

    test('settling a split pays once and clears the request', () async {
      final wallet = FakeWalletRepository(
        initial: const WalletSummary(
          balance: 1000,
          splitsOwed: [
            WalletSplitRequest(id: 's1', amount: 600, requesterName: 'Ada'),
          ],
        ),
      );
      await wallet.settleSplit(
        splitId: 's1',
        accept: true,
        idempotencyKey: 'k',
      );
      await wallet.settleSplit(
        splitId: 's1',
        accept: true,
        idempotencyKey: 'k',
      );
      expect(wallet.summary.balance, 400);
      expect(wallet.summary.splitsOwed, isEmpty);
    });
  });

  test('amount and phone rules', () {
    expect(validateTopUpAmount(null), 'empty');
    expect(validateTopUpAmount(50), 'tooSmall');
    expect(validateTopUpAmount(60000), 'tooLarge');
    expect(validateTopUpAmount(1500), isNull);
    expect(validateSendAmount(40, 1000), 'tooSmall');
    expect(validateSendAmount(1200, 1000), 'insufficient');
    expect(validateSendAmount(800, 1000), isNull);
    expect(normaliseNgPhone('0803 123 4567'), '+2348031234567');
    expect(normaliseNgPhone('+2348031234567'), '+2348031234567');
    expect(normaliseNgPhone('12345'), isNull);
    expect(splitShares(1201, 2), [600, 601]);
    expect(splitShares(1200, 3), [400, 400, 400]);
  });

  group('SupabaseWalletRepository', () {
    test('parses get_wallet and sends keys to the RPCs', () async {
      final gw = FakeAlongSupabase(
        rpcHandler: (fn, p) => switch (fn) {
          'get_wallet' => {
            'balance': 3800.0,
            'currency': 'NGN',
            'entries': [
              {
                'kind': 'send',
                'amount': -1200.0,
                'created_at': '2026-10-28T10:00:00Z',
                'memo': {'to': 'Bayo', 'from': 'Ada'},
              },
              {
                'kind': 'top_up',
                'amount': 5000,
                'created_at': '2026-10-28T09:00:00Z',
                'memo': {'provider': 'stub'},
              },
            ],
            'splits_owed': [
              {'id': 's1', 'amount': 700, 'requester_name': 'Chi'},
            ],
          },
          _ => {'replayed': false},
        },
      );
      final repo = SupabaseWalletRepository(gw);
      final s = await repo.fetch();
      expect(s.balance, 3800);
      expect(s.entries.first.kind, WalletEntryKind.send);
      expect(s.entries.first.counterparty, 'Bayo');
      expect(s.entries.last.counterparty, isNull);
      expect(s.splitsOwed.single.requesterName, 'Chi');

      await repo.topUp(amount: 5000, idempotencyKey: 'topup-123456');
      expect(gw.rpcCalls.last.$1, 'wallet_top_up');
      expect(gw.rpcCalls.last.$2['p_idempotency_key'], 'topup-123456');
    });

    test('maps server error codes', () async {
      final repo = SupabaseWalletRepository(
        FakeAlongSupabase(
          rpcHandler: (fn, p) =>
              throw const PostgrestException(message: 'INSUFFICIENT_FUNDS'),
        ),
      );
      await expectLater(
        repo.buyPass(plan: 'week', idempotencyKey: 'pass-123456'),
        throwsA(
          isA<WalletException>().having(
            (e) => e.failure,
            'failure',
            WalletFailure.insufficientFunds,
          ),
        ),
      );
      expect(walletFailureFor('NOT_FOUND'), WalletFailure.notFound);
      expect(walletFailureFor('boom'), WalletFailure.unavailable);
    });
  });

  test('pass plans: per ride, savings from real fares, active pass', () async {
    const week = WalletPassPlan(id: 'week', rides: 10, price: 4800, days: 7);
    expect(week.perRide, 480);
    expect(week.savingVs(1200), 7200);
    expect(week.savingVs(null), isNull);
    final s = parseWalletSummary({
      'balance': 9000,
      'avg_fare': 1150,
      'pass_plans': [
        {'plan': 'pack', 'rides': 5, 'price': 2600, 'days': 30},
      ],
      'active_pass': {
        'plan': 'pack',
        'rides': 5,
        'expires_at': '2026-11-27T10:00:00Z',
      },
      'splits_requested': [
        {'id': 'a', 'payer_name': 'Ada', 'amount': 600, 'status': 'paid'},
      ],
    });
    expect(s.avgFare, 1150);
    expect(s.passPlans.single.id, 'pack');
    expect(s.activePass!.rides, 5);
    expect(s.splitsSent.single.status, WalletSplitStatus.paid);
    expect(
      parseWalletSummary({'balance': 0}).passPlans,
      walletDefaultPassPlans,
    );

    final fake = FakeWalletRepository(
      initial: const WalletSummary(balance: 5000),
      now: () => DateTime(2026, 10, 28),
    );
    await fake.buyPass(plan: 'week', idempotencyKey: 'p-1');
    await fake.buyPass(plan: 'week', idempotencyKey: 'p-1');
    expect(fake.summary.balance, 200);
    expect(fake.summary.activePass!.expiresAt, DateTime(2026, 11, 4));
  });

  test('split names the missing number and tracks each share', () async {
    final fake = FakeWalletRepository(knownPhones: {'+2348031234567': 'Ada'});
    await expectLater(
      fake.requestSplit(
        phones: ['+2348031234567', '+2348120000000'],
        share: 600,
        idempotencyKey: 's-1',
      ),
      throwsA(
        isA<WalletException>().having(
          (e) => e.detail,
          'detail',
          '+2348120000000',
        ),
      ),
    );
    await fake.requestSplit(
      phones: ['+2348031234567'],
      share: 600,
      idempotencyKey: 's-2',
    );
    expect(fake.summary.splitsSent.single.payerName, 'Ada');
    expect(fake.summary.splitsSent.single.status, WalletSplitStatus.pending);
  });
}

import 'dart:convert';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/wallet/wallet_home_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_pass_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_send_screen.dart';
import 'package:mobile_rider/features/wallet/wallet_split_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Wallet home, top up, send, pass and split: every state, light/dark/1.3x.
void main() {
  setUpAll(() async {
    final manifest = await rootBundle.loadStructuredData<List<dynamic>>(
      'FontManifest.json',
      (s) async => json.decode(s) as List<dynamic>,
    );
    for (final entry in manifest) {
      final loader = FontLoader(entry['family'] as String);
      for (final font in entry['fonts'] as List<dynamic>) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    await AlongFonts.ensureLoaded();
  });

  final now = DateTime(2026, 10, 28, 15);
  final sample = WalletSummary(
    balance: 4200,
    entries: [
      WalletEntry(
        kind: WalletEntryKind.send,
        amount: -1200,
        at: now,
        counterparty: 'Bayo Adeyemi',
      ),
      WalletEntry(kind: WalletEntryKind.topUp, amount: 5000, at: now),
      WalletEntry(
        kind: WalletEntryKind.pass,
        amount: -2000,
        at: now.subtract(const Duration(days: 1)),
      ),
      WalletEntry(
        kind: WalletEntryKind.fare,
        amount: -1200,
        at: now.subtract(const Duration(days: 1)),
      ),
      WalletEntry(
        kind: WalletEntryKind.refund,
        amount: 600,
        at: now.subtract(const Duration(days: 2)),
      ),
    ],
    splitsOwed: const [
      WalletSplitRequest(id: 's1', amount: 600, requesterName: 'Ada Okafor'),
    ],
    avgFare: 1200,
  );
  final rich = sample.copyWith(balance: 9000);
  const statuses = [
    WalletSplitSent(
      id: 'r1',
      payerName: 'Ada Okafor',
      amount: 600,
      status: WalletSplitStatus.paid,
    ),
    WalletSplitSent(
      id: 'r2',
      payerName: 'Chinedu Eze',
      amount: 600,
      status: WalletSplitStatus.pending,
    ),
    WalletSplitSent(
      id: 'r3',
      payerName: 'Bayo Adeyemi',
      amount: 400,
      status: WalletSplitStatus.declined,
    ),
  ];
  const phones = {'+2348031234567': 'Ada Okafor', '+2348059876543': 'Chi'};
  FakeWalletRepository repoOf(WalletSummary s, {bool fail = false}) =>
      FakeWalletRepository(
        initial: s,
        fail: fail,
        knownPhones: phones,
        now: () => now,
      );

  Widget app(
    WalletRepository repo,
    Brightness brightness,
    double scale, {
    Widget home = const WalletScreen(),
  }) {
    return ProviderScope(
      overrides: [
        walletRepositoryProvider.overrideWithValue(repo),
        walletNowProvider.overrideWithValue(() => now),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: alongTheme(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          ),
          child: child!,
        ),
        home: home,
      ),
    );
  }

  Future<void> fill(WidgetTester tester, Map<String, String> fields) async {
    for (final e in fields.entries) {
      await tester.enterText(find.byKey(Key(e.key)), e.value);
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  // (state, repo, screen, setup)
  final cases =
      <
        (
          String,
          FakeWalletRepository Function(),
          Widget,
          Future<void> Function(WidgetTester)?,
        )
      >[
        ('home_filled', () => repoOf(sample), const WalletScreen(), null),
        (
          'home_empty',
          () => repoOf(const WalletSummary(balance: 0)),
          const WalletScreen(),
          null,
        ),
        (
          'home_error',
          () => repoOf(sample, fail: true),
          const WalletScreen(),
          null,
        ),
        ('topup', () => repoOf(sample), const WalletTopUpScreen(), null),
        (
          'send_filled',
          () => repoOf(sample),
          const WalletSendScreen(),
          (t) => fill(t, {
            'wallet_send_phone': '0803 123 4567',
            'wallet_send_amount': '1500',
          }),
        ),
        (
          'send_invalid',
          () => repoOf(sample),
          const WalletSendScreen(),
          (t) async {
            await fill(t, {
              'wallet_send_phone': '0803',
              'wallet_send_amount': '9000',
            });
            await t.tap(find.byKey(const Key('wallet_send_cta')));
            await t.pumpAndSettle();
          },
        ),
        (
          'send_not_found',
          () => repoOf(sample),
          const WalletSendScreen(),
          (t) async {
            await fill(t, {
              'wallet_send_phone': '0812 000 0000',
              'wallet_send_amount': '500',
            });
            await t.tap(find.byKey(const Key('wallet_send_cta')));
            await t.pumpAndSettle();
          },
        ),
        ('pass_ready', () => repoOf(rich), const WalletPassScreen(), null),
        (
          'pass_month',
          () => repoOf(rich),
          const WalletPassScreen(),
          (t) async {
            await t.tap(find.byKey(const Key('wallet_pass_plan_month')));
            await t.pumpAndSettle();
          },
        ),
        (
          'pass_no_history',
          () => repoOf(const WalletSummary(balance: 6000)),
          const WalletPassScreen(),
          null,
        ),
        (
          'pass_no_save',
          () => repoOf(const WalletSummary(balance: 6000, avgFare: 400)),
          const WalletPassScreen(),
          null,
        ),
        (
          'pass_short',
          () => repoOf(const WalletSummary(balance: 500, avgFare: 1200)),
          const WalletPassScreen(),
          null,
        ),
        (
          'pass_bought',
          () => repoOf(rich),
          const WalletPassScreen(),
          (t) async {
            await t.tap(find.byKey(const Key('wallet_pass_cta')));
            await t.pumpAndSettle();
          },
        ),
        (
          'pass_active',
          () => repoOf(
            WalletSummary(
              balance: 4200,
              avgFare: 1200,
              activePass: WalletActivePass(
                plan: 'pack',
                rides: 5,
                expiresAt: DateTime(2026, 11, 27),
              ),
            ),
          ),
          const WalletPassScreen(initialPlan: 'pack'),
          null,
        ),
        (
          'split_filled',
          () => repoOf(sample),
          const WalletSplitScreen(),
          (t) => fill(t, {
            'wallet_split_fare': '1200',
            'wallet_split_phone_0': '0803 123 4567',
          }),
        ),
        (
          'split_status',
          () => repoOf(sample.copyWith(splitsSent: statuses)),
          const WalletSplitScreen(),
          null,
        ),
        (
          'split_not_found',
          () => repoOf(sample),
          const WalletSplitScreen(),
          (t) async {
            await t.tap(find.byKey(const Key('wallet_split_add')));
            await t.pumpAndSettle();
            await fill(t, {
              'wallet_split_fare': '1800',
              'wallet_split_phone_0': '0803 123 4567',
              'wallet_split_phone_1': '0812 000 0000',
            });
            await t.tap(find.byKey(const Key('wallet_split_cta')));
            await t.pumpAndSettle();
          },
        ),
      ];

  for (final (name, brightness, scale) in [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('light_1_3x', Brightness.light, 1.3),
  ]) {
    for (final (state, repo, screen, setup) in cases) {
      testWidgets('rider wallet $state $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(app(repo(), brightness, scale, home: screen));
        await tester.pumpAndSettle();
        if (setup != null) await setup(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/rider_wallet_${state}_$name.png'),
        );
      });
    }
  }

  testWidgets('top up from home credits once and updates the balance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallet_action_topup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topup_5000')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('topup_add')));
    await tester.pumpAndSettle();
    expect(repo.summary.balance, 9200);
    expect(find.text('₦5,000 added'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('₦9,200'), findsOneWidget);
  });

  testWidgets('custom top up is validated before it is sent', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample);
    await tester.pumpWidget(
      app(repo, Brightness.light, 1, home: const WalletTopUpScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topup_custom')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('topup_add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('wallet_custom_field')), '50');
    await tester.tap(find.byKey(const Key('wallet_custom_add')));
    await tester.pump();
    expect(find.text('At least ₦100'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('wallet_custom_field')),
      '1500',
    );
    await tester.tap(find.byKey(const Key('wallet_custom_add')));
    await tester.pumpAndSettle();
    expect(repo.summary.balance, 5700);
  });

  testWidgets('send moves credit once and returns home', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallet_action_send')));
    await tester.pumpAndSettle();
    await fill(tester, {
      'wallet_send_phone': '0803 123 4567',
      'wallet_send_amount': '1500',
    });
    await tester.tap(find.byKey(const Key('wallet_send_cta')));
    await tester.pumpAndSettle();
    expect(repo.summary.balance, 2700);
    expect(find.byKey(const Key('wallet_home')), findsOneWidget);
    expect(find.text('To Ada Okafor'), findsOneWidget);
  });

  testWidgets('send over the balance is blocked on the client', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample);
    await tester.pumpWidget(
      app(repo, Brightness.light, 1, home: const WalletSendScreen()),
    );
    await tester.pumpAndSettle();
    await fill(tester, {
      'wallet_send_phone': '0803 123 4567',
      'wallet_send_amount': '9000',
    });
    await tester.tap(find.byKey(const Key('wallet_send_cta')));
    await tester.pumpAndSettle();
    expect(find.text('More than your balance'), findsOneWidget);
    expect(repo.summary.balance, 4200);
  });

  testWidgets('pass buys once', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(rich);
    await tester.pumpWidget(
      app(repo, Brightness.light, 1, home: const WalletPassScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('₦7,200'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wallet_pass_plan_pack')));
    await tester.pumpAndSettle();
    expect(find.text('₦520 a ride · Good for 30 days'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wallet_pass_cta')));
    await tester.pumpAndSettle();
    expect(repo.summary.balance, 6400);
    expect(repo.summary.activePass?.plan, 'pack');
    expect(find.byKey(const Key('wallet_pass_done')), findsOneWidget);
  });

  testWidgets('pass with a short balance offers a top up', (tester) async {
    final poor = repoOf(const WalletSummary(balance: 500));
    await tester.pumpWidget(
      app(poor, Brightness.light, 1, home: const WalletPassScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet_pass_no_history')), findsOneWidget);
    expect(find.text('Top up ₦4,300 more to buy'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wallet_pass_topup')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('topup_add')), findsOneWidget);
  });

  testWidgets('split asks each co-rider for an equal share', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample);
    await tester.pumpWidget(
      app(repo, Brightness.light, 1, home: const WalletSplitScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallet_split_add')));
    await tester.pumpAndSettle();
    await fill(tester, {
      'wallet_split_fare': '1800',
      'wallet_split_phone_0': '0803 123 4567',
      'wallet_split_phone_1': '0805 987 6543',
    });
    expect(find.text('Request ₦600 each'), findsOneWidget);
    await tester.tap(find.byKey(const Key('wallet_split_cta')));
    await tester.pumpAndSettle();
    expect(find.text('Asked 2 co-riders'), findsOneWidget);
    expect(repo.summary.splitsSent, hasLength(2));
    expect(find.text('Waiting'), findsNWidgets(2));
  });

  testWidgets('split names the number that is not on Along', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      app(repoOf(sample), Brightness.light, 1, home: const WalletSplitScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallet_split_add')));
    await tester.pumpAndSettle();
    await fill(tester, {
      'wallet_split_fare': '1800',
      'wallet_split_phone_0': '0803 123 4567',
      'wallet_split_phone_1': '0812 000 0000',
    });
    await tester.tap(find.byKey(const Key('wallet_split_cta')));
    await tester.pumpAndSettle();
    expect(find.text("0812 000 0000 isn't on Along yet"), findsOneWidget);
    expect(find.text('Not on Along yet'), findsOneWidget);
  });

  testWidgets('paying a split request debits once and clears it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('wallet_owed_pay_s1')));
    await tester.pumpAndSettle();
    expect(repo.summary.balance, 3600);
    expect(find.byKey(const Key('wallet_owed_s1')), findsNothing);
    expect(find.text('Paid ₦600'), findsOneWidget);
  });

  testWidgets('error state retries', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = repoOf(sample, fail: true);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet_error')), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.byKey(const Key('wallet_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet_home')), findsOneWidget);
  });
}

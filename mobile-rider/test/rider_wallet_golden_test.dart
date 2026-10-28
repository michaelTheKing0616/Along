import 'dart:convert';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/wallet/wallet_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Wallet top up: filled, empty and error, light/dark/1.3x.
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
      WalletEntry(kind: WalletEntryKind.topUp, amount: 2000, at: now),
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
  );

  Widget app(WalletRepository repo, Brightness brightness, double scale) {
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
        home: const WalletScreen(),
      ),
    );
  }

  for (final (name, brightness, scale) in [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('light_1_3x', Brightness.light, 1.3),
  ]) {
    for (final (state, repo) in [
      ('filled', () => FakeWalletRepository(initial: sample)),
      ('empty', () => FakeWalletRepository()),
      ('error', () => FakeWalletRepository(fail: true)),
    ]) {
      testWidgets('rider wallet $state $name', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(app(repo(), brightness, scale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/rider_wallet_${state}_$name.png'),
        );
      });
    }
  }

  testWidgets('a top up credits once and updates the balance', (tester) async {
    final repo = FakeWalletRepository(initial: sample);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('topup_5000')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('topup_add')));
    await tester.pumpAndSettle();
    expect((await repo.fetch()).balance, 9200);
    expect(find.text('₦5,000 added'), findsOneWidget);
  });

  testWidgets('custom amount is validated before it is sent', (tester) async {
    final repo = FakeWalletRepository(initial: sample);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
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
    expect((await repo.fetch()).balance, 5700);
  });

  testWidgets('error state retries', (tester) async {
    final repo = FakeWalletRepository(initial: sample, fail: true);
    await tester.pumpWidget(app(repo, Brightness.light, 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet_error')), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.byKey(const Key('wallet_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wallet_topup')), findsOneWidget);
  });
}

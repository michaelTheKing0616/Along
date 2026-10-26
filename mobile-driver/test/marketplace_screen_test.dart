import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/marketplace/presentation/marketplace_screen.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

void main() {
  testWidgets('a driver target shows the seats still needed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MarketplaceScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('marketplace_goal')), '2000');
    await tester.enterText(find.byKey(const Key('marketplace_earned')), '500');
    await tester.enterText(find.byKey(const Key('marketplace_typical')), '500');
    await tester.pump();
    expect(find.text('3 seats to go'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('marketplace_corridor')),
      'Nyanya',
    );
    await tester.enterText(find.byKey(const Key('marketplace_requests')), '11');
    await tester.ensureVisible(
      find.byKey(const Key('marketplace_add_corridor')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('marketplace_add_corridor')));
    await tester.pump();
    expect(find.text('Queue toward Nyanya'), findsOneWidget);
    expect(find.textContaining('₦'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

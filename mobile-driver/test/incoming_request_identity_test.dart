import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_notifier.dart';
import 'package:mobile_driver/features/incoming_request/presentation/incoming_request_sheet.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

import 'support/pricing_fixtures.dart';

void main() {
  Widget buildIncomingSheet(IncomingRequestState state) {
    return MaterialApp(
      theme: alongTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: IncomingRequestSheet(
          state: state,
          l10n: lookupAppLocalizations(const Locale('en')),
          onAccept: () {},
          onDecline: () {},
        ),
      ),
    );
  }

  IncomingRequestState roamingCascadeState({
    bool unconfirmedFare = true,
    int dispatchAttempt = 2,
  }) {
    final trip = DomainMappers.incomingTripFromEnvelope(
      sampleRoamingTripRequestEnvelope(
        dispatchAttempt: dispatchAttempt,
        unconfirmedFare: unconfirmedFare,
        riderPhone: '+2348000001234',
      ),
    );
    return IncomingRequestState(
      trip: trip,
      commissionRate: 0.075,
      requestTtlS: 25,
      remainingSeconds: 18,
      maxCascade: 3,
    );
  }

  group('identity gate — incoming + negotiation sheets', () {
    testWidgets('incoming sheet never renders rider phone even if payload leaks it',
        (tester) async {
      await tester.pumpWidget(buildIncomingSheet(roamingCascadeState()));
      await tester.pumpAndSettle();

      expect(find.textContaining('+234'), findsNothing);
      expect(find.textContaining('8000001234'), findsNothing);
      // Tier B display_name is allowed once trip is requested.
      expect(find.textContaining('Ada'), findsOneWidget);
    });

    testWidgets('negotiation sheet never renders rider display_name or phone',
        (tester) async {
      final view = NegotiationView.fromJson(
        sampleNegotiationView(
          context: 'roaming',
          etaBand: 'single',
          amount: '550.00',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: alongTheme(),
          home: Scaffold(
            body: NegotiationSheet(
              key: const Key('driver_negotiation_sheet'),
              variant: NegotiationSheetVariant.roamingSingle,
              anchorNaira: view.anchorNaira,
              chipSteps: view.chipStepsNaira,
              proposedNaira: view.amountNaira,
              roundNumber: view.round,
              roundCap: view.roundCap,
              countdownSeconds: 30,
              countdownTotal: 60,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ada'), findsNothing);
      expect(find.textContaining('+234'), findsNothing);
      expect(find.byKey(const Key('driver_negotiation_sheet')), findsOneWidget);
    });

    testWidgets('roaming cascade incoming shows retry badge and cell hail pickup',
        (tester) async {
      await tester.pumpWidget(buildIncomingSheet(roamingCascadeState()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incoming_request_cascade_badge')), findsOneWidget);
      expect(find.text('Retry 2 of 3'), findsOneWidget);
      expect(find.textContaining('Rider location'), findsOneWidget);
      expect(find.text('Cell hail — meet at pin'), findsOneWidget);
    });

    testWidgets('tier-3 roaming hail shows estimate pill', (tester) async {
      await tester.pumpWidget(
        buildIncomingSheet(roamingCascadeState(unconfirmedFare: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('incoming_request_estimate_pill')), findsOneWidget);
      expect(find.textContaining('Estimate'), findsWidgets);
    });
  });
}

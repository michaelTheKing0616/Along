import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_rider/features/trip_options/domain/load_capacity_warning.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/load_flag_sheet.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

void main() {
  const warnCapacities = {
    'small': ['none'],
    'medium': ['none', 'small'],
    'large': ['none', 'small', 'medium'],
  };

  group('FM36 load capacity warning (R-09)', () {
    test('shouldWarnLoadCapacity warns for okada none + medium load', () {
      expect(
        shouldWarnLoadCapacity(
          loadSize: 'medium',
          modeLoadCapacity: 'none',
          warnCapacities: warnCapacities,
        ),
        isTrue,
      );
    });

    test('shouldWarnLoadCapacity hides for car large + small load', () {
      expect(
        shouldWarnLoadCapacity(
          loadSize: 'small',
          modeLoadCapacity: 'large',
          warnCapacities: warnCapacities,
        ),
        isFalse,
      );
    });

    testWidgets('shows warning and Request anyway for okada + medium', (
      tester,
    ) async {
      LoadFlagState? applied;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoadFlagSheet(
              initial: const LoadFlagState(flagged: true, size: 'medium'),
              warnCapacities: warnCapacities,
              modeLoadCapacity: 'none',
              onApply: (load) => applied = load,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('load_flag_request_anyway')), findsOneWidget);
      expect(find.byKey(const Key('load_flag_done')), findsNothing);
      expect(find.text('This mode may not fit your load'), findsOneWidget);

      await tester.tap(find.byKey(const Key('load_flag_request_anyway')));
      await tester.pump();

      expect(applied?.acknowledgedWarning, isTrue);
      expect(applied?.size, 'medium');
    });

    testWidgets('hides warning for car + small load', (tester) async {
      LoadFlagState? applied;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoadFlagSheet(
              initial: const LoadFlagState(flagged: true, size: 'small'),
              warnCapacities: warnCapacities,
              modeLoadCapacity: 'large',
              onApply: (load) => applied = load,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('load_flag_done')), findsOneWidget);
      expect(find.byKey(const Key('load_flag_request_anyway')), findsNothing);

      await tester.tap(find.byKey(const Key('load_flag_done')));
      await tester.pump();

      expect(applied?.acknowledgedWarning, isFalse);
      expect(applied?.size, 'small');
    });

    testWidgets('updates warning when size chip changes to medium', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LoadFlagSheet(
              initial: const LoadFlagState(flagged: true, size: 'small'),
              warnCapacities: warnCapacities,
              modeLoadCapacity: 'small',
              onApply: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('load_flag_done')), findsOneWidget);
      expect(find.byKey(const Key('load_flag_request_anyway')), findsNothing);

      await tester.tap(find.byKey(const Key('load_size_medium')));
      await tester.pump();

      expect(find.byKey(const Key('load_flag_request_anyway')), findsOneWidget);
      expect(find.byKey(const Key('load_flag_done')), findsNothing);
    });
  });
}

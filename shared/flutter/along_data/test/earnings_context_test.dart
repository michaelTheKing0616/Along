import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses online time and latest payout', () {
    final ctx = DriverEarningsContext.fromJson({
      'from': '2026-10-18T23:00:00Z',
      'online_seconds_by_day': {'2026-10-25': 24000},
      'latest_payout': {
        'status': 'confirmed',
        'amount': 9600,
        'currency': 'NGN',
        'created_at': '2026-10-23T09:00:00Z',
        'confirmed_at': '2026-10-23T09:05:00Z',
        'account_label': 'GTBank ••4821',
        'bank_name': 'GTBank',
        'account_last4': '4821',
      },
    });
    expect(ctx.onlineSecondsByDay['2026-10-25'], 24000);
    expect(ctx.latestPayout?.status, DriverPayoutStatus.confirmed);
    expect(ctx.latestPayout?.amount.minorUnits, 960000);
    expect(ctx.latestPayout?.bankName, 'GTBank');
    expect(ctx.latestPayout?.accountLast4, '4821');
  });

  test('handoff carries the PIN and a contact flag, never a phone', () {
    expect(TripPickupHandoff.fromJson(null), isNull);
    expect(
      TripPickupHandoff.fromJson({'pin': null, 'contact_available': false}),
      isNull,
    );
    final h = TripPickupHandoff.fromJson({
      'pin': '0482',
      'contact_available': true,
    });
    expect(h?.pin, '0482');
    expect(h?.contactAvailable, isTrue);
    expect(TripPickupHandoff.fromJson({'pin': '12'}), isNull);
  });

  test('PIN result and contact action parse', () {
    final r = TripPinResult.fromJson({
      'verified': false,
      'attempts_left': 3,
      'locked': false,
    });
    expect(r.verified, isFalse);
    expect(r.attemptsLeft, 3);
    final a = TripContactAction.fromJson({
      'uri': 'tel:+2348031234567',
      'masked': false,
      'expires_at': '2026-10-25T20:02:00Z',
    });
    expect(a?.uri.scheme, 'tel');
    expect(TripContactAction.fromJson({'uri': 'https://x'}), isNull);
  });

  test('Na Me tap options and match result parse', () {
    final o = NaMeTapOptions.fromJson({
      'options': [
        {
          'color_token': 'color.naMe.green',
          'shape': 'circle',
          'label': 'Green Circle',
        },
        {
          'color_token': 'color.naMe.blue',
          'shape': 'star',
          'label': 'Blue Star',
        },
      ],
      'tap_locked': true,
      'attempts_left': 2,
    });
    expect(o.options.map((e) => e.label), ['Green Circle', 'Blue Star']);
    expect(o.tapLocked, isTrue);
    expect(o.attemptsLeft, 2);
    final m = NaMeMatchResult.fromJson({
      'matched': false,
      'attempts_left': 1,
      'tap_locked': true,
      'rate_limited': true,
    });
    expect(m.matched, isFalse);
    expect(m.tapLocked, isTrue);
    expect(m.rateLimited, isTrue);
    expect(NaMeMatchResult.fromJson(null).matched, isFalse);
  });

  test('lagosDayStart is Lagos midnight in UTC', () {
    expect(
      lagosDayStart(DateTime.utc(2026, 10, 25, 9), daysBack: 6),
      DateTime.utc(2026, 10, 18, 23),
    );
  });
}

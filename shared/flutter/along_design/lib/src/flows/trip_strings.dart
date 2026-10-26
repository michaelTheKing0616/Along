import 'package:flutter/widgets.dart';

/// Copy for the live trip, pickup handoff and receipt widgets.
///
/// English by default so the gallery and goldens read without a host app.
/// A host app wraps its screens in [AlongTripStrings.scope] with its own
/// translations; the widgets read it with [AlongTripStrings.of].
class AlongTripStrings {
  const AlongTripStrings({
    this.workingOut = 'Working out your arrival',
    this.lastEstimateTo = _lastEstimateTo,
    this.arrivingAt = _arrivingAt,
    this.livePaused = 'Live times paused',
    this.retry = 'Retry',
    this.trafficLater = _trafficLater,
    this.minUnit = 'min',
    this.aboutClock = _aboutClock,
    this.clockRange = _clockRange,
    this.minutesLabel = _minutesLabel,
    this.minutesRangeLabel = _minutesRangeLabel,
    this.emergency = 'Emergency',
    this.sos = 'SOS',
    this.call = 'Call',
    this.callName = _callName,
    this.message = 'Message',
    this.messageName = _messageName,
    this.arrivesIn = _arrivesIn,
    this.isHere = _isHere,
    this.driverHere = 'Driver is here',
    this.meetAtPickup = 'Meet at pickup',
    this.countdownLabel = _countdownLabel,
    this.tripPin = 'Trip PIN',
    this.sayAtDoor = 'Say it at the door',
    this.newPin = 'Get a new PIN',
    this.receiptTitle = 'Receipt',
    this.receiptNotReady = 'Receipt not ready',
    this.receiptNotReadyBody =
        'It is still on its way. It will also be in Trips.',
    this.tryAgain = 'Try again',
    this.done = 'Done',
    this.howWas = _howWas,
    this.fare = 'Fare',
    this.total = 'Total',
    this.cashPaid = 'Cash paid',
    this.changeToWallet = 'Change to wallet',
    this.walletNow = _walletNow,
  });

  final String workingOut;
  final String Function(String destination) lastEstimateTo;
  final String Function(String destination) arrivingAt;
  final String livePaused;
  final String retry;
  final String Function(int minutes) trafficLater;
  final String minUnit;
  final String Function(String clock) aboutClock;
  final String Function(String first, String last) clockRange;
  final String Function(int minutes) minutesLabel;
  final String Function(int low, int high) minutesRangeLabel;
  final String emergency;
  final String sos;
  final String call;
  final String Function(String name) callName;
  final String message;
  final String Function(String name) messageName;
  final String Function(String name) arrivesIn;
  final String Function(String name) isHere;
  final String driverHere;
  final String meetAtPickup;
  final String Function(int minutes, int seconds) countdownLabel;
  final String tripPin;
  final String sayAtDoor;
  final String newPin;
  final String receiptTitle;
  final String receiptNotReady;
  final String receiptNotReadyBody;
  final String tryAgain;
  final String done;
  final String Function(String name) howWas;
  final String fare;
  final String total;
  final String cashPaid;
  final String changeToWallet;
  final String Function(String amount) walletNow;

  static const english = AlongTripStrings();

  static AlongTripStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Scope>()?.strings ?? english;

  /// Provides [strings] to every trip widget below.
  static Widget scope({
    required AlongTripStrings strings,
    required Widget child,
  }) => _Scope(strings: strings, child: child);

  static String _lastEstimateTo(String d) => 'Last estimate to $d';
  static String _arrivingAt(String d) => 'Arriving at $d';
  static String _trafficLater(int m) => 'Traffic ahead. About $m min later.';
  static String _aboutClock(String c) => 'About $c';
  static String _clockRange(String a, String b) => '$a to $b';
  static String _minutesLabel(int m) => '$m minutes';
  static String _minutesRangeLabel(int a, int b) => '$a to $b minutes';
  static String _callName(String n) => 'Call $n';
  static String _messageName(String n) => 'Message $n';
  static String _arrivesIn(String n) => '$n arrives in';
  static String _isHere(String n) => '$n is here';
  static String _countdownLabel(int m, int s) => '$m minutes $s seconds';
  static String _howWas(String n) => 'How was $n?';
  static String _walletNow(String a) => 'Wallet now $a';
}

class _Scope extends InheritedWidget {
  const _Scope({required this.strings, required super.child});

  final AlongTripStrings strings;

  @override
  bool updateShouldNotify(_Scope old) => old.strings != strings;
}

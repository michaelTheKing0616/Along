import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Shared pieces for the request-to-receipt screens: the map-over-sheet
/// layout, mode glyphs, money in whole naira and the localised trip copy.

IconData tripModeIcon(String code) => switch (code) {
  'keke' => AlongIcons.keke,
  'okada' => AlongIcons.okada,
  'danfo' || 'minibus' => AlongIcons.danfo,
  'bus' || 'brt' => AlongIcons.bus,
  _ => AlongIcons.taxi,
};

/// Whole naira for design widgets that take a major amount. Rounds the
/// kobo instead of dropping them, so ₦449.60 reads ₦450, not ₦449.
int majorUnits(Money money) => (money.minorUnits / 100).round();

/// Map coordinates as Offset(lng, lat) for [AlongRoutePreview].
Offset? lngLat(GeoPoint? point) =>
    point == null ? null : Offset(point.lng, point.lat);

/// How far [at] has come from [from] towards [to], 0..1, by straight-line
/// distance. Null when any point is missing or the two ends coincide.
double? progressBetween(GeoPoint? from, GeoPoint? to, GeoPoint? at) {
  if (from == null || to == null || at == null) return null;
  final total = haversineDistanceM(from, to);
  if (total < 1) return null;
  final left = haversineDistanceM(at, to);
  return (1 - left / total).clamp(0.0, 1.0);
}

/// Copy for the design package's live trip, handoff and receipt widgets.
AlongTripStrings riderTripStrings(AppLocalizations l10n) => AlongTripStrings(
  workingOut: l10n.tripEtaWorkingOut,
  lastEstimateTo: l10n.tripEtaLastTo,
  arrivingAt: l10n.tripEtaArrivingAt,
  livePaused: l10n.tripEtaPaused,
  retry: l10n.tripRetry,
  trafficLater: l10n.tripEtaTraffic,
  minUnit: l10n.tripMinUnit,
  aboutClock: l10n.tripAboutClock,
  clockRange: l10n.tripClockRange,
  minutesLabel: l10n.tripMinutesLabel,
  minutesRangeLabel: l10n.tripMinutesRangeLabel,
  emergency: l10n.tripEmergency,
  sos: l10n.tripSos,
  call: l10n.tripCall,
  callName: l10n.tripCallName,
  message: l10n.tripMessage,
  messageName: l10n.activeTripMessage,
  arrivesIn: l10n.tripArrivesIn,
  isHere: l10n.tripIsHere,
  driverHere: l10n.tripDriverHere,
  meetAtPickup: l10n.tripMeetAtPickup,
  countdownLabel: l10n.tripCountdownLabel,
  tripPin: l10n.tripPinTitle,
  sayAtDoor: l10n.tripPinSay,
  newPin: l10n.tripPinNew,
  receiptTitle: l10n.receiptTitle,
  receiptNotReady: l10n.receiptNotReady,
  receiptNotReadyBody: l10n.receiptNotReadyBody,
  tryAgain: l10n.receiptTryAgain,
  done: l10n.receiptDone,
  howWas: l10n.receiptHowWas,
  fare: l10n.receiptFare,
  total: l10n.receiptTotal,
  cashPaid: l10n.receiptCashPaid,
  changeToWallet: l10n.receiptChangeToWallet,
  walletNow: l10n.receiptWalletNow,
);

/// Wraps [child] so every design trip widget below speaks the app locale.
class RiderTripStrings extends StatelessWidget {
  const RiderTripStrings({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AlongTripStrings.scope(
    strings: riderTripStrings(AppLocalizations.of(context)),
    child: child,
  );
}

/// A drawn map on top and a squircle sheet below it, with optional map
/// buttons and a footer pinned above the home indicator.
///
/// The map gets the insets it must keep clear: the button row on top and
/// the sheet's rounded overlap below.
class TripSheetScaffold extends StatelessWidget {
  const TripSheetScaffold({
    super.key,
    required this.map,
    required this.children,
    this.mapFraction = 0.42,
    this.leading,
    this.trailing,
    this.footer,
    this.sheetKey,
  });

  final Widget Function(double topInset, double bottomInset) map;
  final List<Widget> children;
  final double mapFraction;
  final Widget? leading;
  final Widget? trailing;
  final Widget? footer;
  final Key? sheetKey;

  static const double _overlap = 28;

  @override
  Widget build(BuildContext context) {
    final palette = AlongPalette.of(context);
    final padding = MediaQuery.paddingOf(context);
    return RiderTripStrings(
      child: Scaffold(
        backgroundColor: palette.surface,
        body: LayoutBuilder(
          builder: (context, box) {
            final mapHeight = box.maxHeight * mapFraction;
            return Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: mapHeight + _overlap,
                  child: map(padding.top + 64, _overlap),
                ),
                if (leading != null || trailing != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AlongSpace.s16),
                        child: Row(
                          children: [
                            if (leading != null) leading!,
                            const Spacer(),
                            if (trailing != null) trailing!,
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  top: mapHeight,
                  child: DecoratedBox(
                    key: sheetKey,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: AlongRadius.dialog,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AlongSpace.s16,
                              AlongSpace.s20,
                              AlongSpace.s16,
                              AlongSpace.s16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children,
                            ),
                          ),
                        ),
                        if (footer != null)
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              AlongSpace.s16,
                              0,
                              AlongSpace.s16,
                              AlongSpace.s12 + padding.bottom,
                            ),
                            child: footer,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A soft, squircle notice line inside a trip sheet.
class TripNotice extends StatelessWidget {
  const TripNotice({
    super.key,
    required this.icon,
    required this.text,
    this.warn = false,
  });

  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final warnInk = AlongRoles.of(p).warn;
    final ink = warn ? warnInk : p.ink;
    return DecoratedBox(
      decoration: AlongCraft.compactFill(
        warn ? warnInk.withValues(alpha: 0.12) : p.recessed,
        44,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            AlongIcon(icon, size: 18, color: ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: AlongType.label(p).copyWith(color: ink)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mode glyph in a recessed squircle, the same tile the trip options use.
class TripModeTile extends StatelessWidget {
  const TripModeTile({super.key, required this.modeCode, this.size = 44});

  final String modeCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: AlongCraft.compactFill(p.recessed, size),
        child: Center(
          child: AlongIcon(tripModeIcon(modeCode), size: 22, color: p.ink),
        ),
      ),
    );
  }
}

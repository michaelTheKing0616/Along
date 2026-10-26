import 'dart:math' as math;

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
  clockOffset: cityUtcOffset,
  minutesLabel: l10n.tripMinutesLabel,
  minutesRangeLabel: l10n.tripMinutesRangeLabel,
  emergency: l10n.tripEmergency,
  sos: l10n.tripSos,
  holdForSos: l10n.tripHoldForSos,
  naMe: l10n.tripNaMe,
  call112: l10n.tripCall112,
  fired: l10n.tripSignalSent,
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
                          child: ShaderMask(
                            // Content fades out above the pinned footer
                            // instead of being cut off under it.
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (r) => LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: const [
                                Color(0xFFFFFFFF),
                                Color(0xFFFFFFFF),
                                Color(0x00FFFFFF),
                              ],
                              stops: [0, 1 - (20 / r.height).clamp(0, 1), 1],
                            ).createShader(r),
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

/// Along runs in Nigerian cities, all on Africa/Lagos (UTC+1, no DST), so
/// trip clocks read in city time whatever zone the phone is set to.
const Duration cityUtcOffset = Duration(hours: 1);

/// [t] as wall-clock time in the trip city.
DateTime cityTime(DateTime t) => t.toUtc().add(cityUtcOffset);

/// The driver's initial on a squircle tile, standing in for a photo.
class TripDriverAvatar extends StatelessWidget {
  const TripDriverAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: AlongCraft.compactFill(p.ink, size, corner: size * 0.34),
        child: Text(
          initial,
          style: AlongType.title(p).copyWith(color: p.onInk, height: 1),
        ),
      ),
    );
  }
}

/// A compact squircle action: icon over a short label. Used in rows of
/// equal-weight trip actions so none reads as bare text.
class TripActionTile extends StatelessWidget {
  const TripActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final enabled = onPressed != null;
    final fg = enabled ? p.ink : p.muted;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          shape: AlongCraft.border(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    AlongHaptics.tick(context);
                    onPressed!();
                  },
            child: Ink(
              decoration: AlongCraft.compactFill(p.recessed, 64, corner: 16),
              padding: const EdgeInsets.symmetric(
                horizontal: AlongSpace.s4,
                vertical: AlongSpace.s12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: badge > 0,
                    label: Text('$badge'),
                    backgroundColor: p.danger,
                    child: AlongIcon(icon, size: 22, color: fg),
                  ),
                  const SizedBox(height: AlongSpace.s4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.caption(p).copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How far along the ride is, board to alight, as a squircle track.
class TripProgressBar extends StatelessWidget {
  const TripProgressBar({
    super.key,
    required this.progress,
    required this.from,
    required this.to,
  });

  final double progress;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final v = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 8,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: AlongCraft.compactFill(
                      p.recessed,
                      8,
                      corner: 4,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: v),
                  duration: AlongMoves.arrive.of(context),
                  curve: AlongMoves.arrive.curve,
                  builder: (context, t, _) => Container(
                    width: math.max(8, box.maxWidth * t),
                    decoration: AlongCraft.compactFill(p.ink, 8, corner: 4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AlongSpace.s4),
        Row(
          children: [
            Expanded(
              child: Text(
                from,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AlongType.caption(p),
              ),
            ),
            const SizedBox(width: AlongSpace.s8),
            Expanded(
              child: Text(
                to,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AlongType.caption(p),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A content-sized modal sheet in trip style: grabber, optional icon tile,
/// title and subtitle, a scrolling body and an optional pinned footer.
class TripModalSheet extends StatelessWidget {
  const TripModalSheet({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.footer,
    this.maxHeightFraction = 0.9,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;
  final Widget? footer;
  final double maxHeightFraction;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final media = MediaQuery.of(context);
    final tone = iconColor ?? p.ink;
    return RiderTripStrings(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: media.size.height * maxHeightFraction,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(
                top: AlongRadius.dialog,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AlongSpace.s12),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: AlongCraft.compactFill(p.line, 4, corner: 2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AlongSpace.s20,
                      AlongSpace.s16,
                      AlongSpace.s20,
                      AlongSpace.s12,
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: AlongCraft.compactFill(
                              tone.withValues(alpha: 0.12),
                              40,
                              corner: 14,
                            ),
                            child: AlongIcon(icon!, size: 20, color: tone),
                          ),
                          const SizedBox(width: AlongSpace.s12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: AlongType.title(p)),
                              if (subtitle != null)
                                Text(subtitle!, style: AlongType.caption(p)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AlongSpace.s20,
                        0,
                        AlongSpace.s20,
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
                      padding: const EdgeInsets.fromLTRB(
                        AlongSpace.s20,
                        0,
                        AlongSpace.s20,
                        AlongSpace.s12,
                      ),
                      child: footer,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recessed squircle panel for grouped content inside sheets and pages.
class TripPanel extends StatelessWidget {
  const TripPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.compactFill(p.recessed, 64, corner: 20),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AlongSpace.s16),
        child: child,
      ),
    );
  }
}

/// Filled squircle text input, palette-aware, focus ring in ink.
InputDecoration tripInputDecoration(AlongPalette p, {String? hint}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: AlongType.bodyMuted(p),
      filled: true,
      fillColor: p.recessed,
      contentPadding: const EdgeInsets.all(AlongSpace.s16),
      border: AlongCraft.input(BorderSide.none),
      enabledBorder: AlongCraft.input(BorderSide.none),
      focusedBorder: AlongCraft.input(BorderSide(color: p.ink, width: 1.5)),
      counterStyle: AlongType.caption(p),
    );

/// A full-screen page in trip style: back button, large title, optional
/// subtitle, scrolling body and an optional pinned footer.
class TripPage extends StatelessWidget {
  const TripPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.trailing,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final canPop = Navigator.of(context).canPop();
    return RiderTripStrings(
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s16,
                  AlongSpace.s8,
                  AlongSpace.s16,
                  0,
                ),
                child: Row(
                  children: [
                    if (canPop || onBack != null)
                      AlongMapButton(
                        key: const Key('trip_page_back'),
                        icon: AlongIcons.back,
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    const Spacer(),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AlongSpace.s20,
                    AlongSpace.s16,
                    AlongSpace.s20,
                    AlongSpace.s24,
                  ),
                  children: [
                    Text(title, style: AlongType.display(p)),
                    if (subtitle != null) ...[
                      const SizedBox(height: AlongSpace.s4),
                      Text(subtitle!, style: AlongType.bodyMuted(p)),
                    ],
                    const SizedBox(height: AlongSpace.s20),
                    ...children,
                  ],
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AlongSpace.s20,
                    AlongSpace.s8,
                    AlongSpace.s20,
                    AlongSpace.s12,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A selectable squircle tile with an icon above a label.
class TripChoiceTile extends StatelessWidget {
  const TripChoiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final fg = selected ? p.onInk : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? p.ink : p.recessed,
          shape: AlongCraft.border(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              AlongHaptics.tick(context);
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.all(AlongSpace.s12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AlongIcon(icon, size: 22, color: fg),
                  const SizedBox(height: AlongSpace.s8),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.label(p).copyWith(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

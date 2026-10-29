import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/vehicle_marker_panel.dart';

/// Opens a dialer, WhatsApp, SMS or a link outside the app. Tests record.
final safetyLauncherProvider = Provider<Future<bool> Function(Uri uri)>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);

/// Wall clock for safety timestamps. Goldens pin it.
final safetyNowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

String safetyClock(DateTime t) => DateFormat.Hm().format(t.toLocal());

/// Initials for a contact monogram: "Ada Obi" → "AO", "chidi" → "CH".
String safetyInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final w = parts.first;
    return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
  }
  return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
}

String safetyFirstName(String name) {
  final t = name.trim();
  if (t.isEmpty) return name;
  return t.split(RegExp(r'\s+')).first;
}

/// Page shell shared by SOS and Guardian: display title, one status line,
/// body, footer. Paper surface, 24 pt gutters, like the rest of the app.
class SafetyPage extends StatelessWidget {
  const SafetyPage({
    super.key,
    required this.title,
    required this.status,
    required this.child,
    this.footer,
    this.canClose = true,
  });

  final String title;
  final Widget status;
  final Widget child;
  final Widget? footer;
  final bool canClose;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final canPop = canClose && Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AlongType.display(p),
                    ),
                  ),
                  if (canPop)
                    Transform.translate(
                      offset: const Offset(12, 0),
                      child: CloseButton(color: p.ink),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              status,
              const SizedBox(height: 16),
              Expanded(child: child),
              if (footer != null) ...[const SizedBox(height: 16), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tone of the single status line under the title.
enum SafetyTone { idle, working, ok, waiting, alarm }

class SafetyStatusLine extends StatelessWidget {
  const SafetyStatusLine({super.key, required this.label, required this.tone});

  final String label;
  final SafetyTone tone;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final color = switch (tone) {
      SafetyTone.alarm => p.danger,
      _ => p.ink,
    };
    final Widget lead = switch (tone) {
      SafetyTone.working => SizedBox.square(
        dimension: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: p.ink),
      ),
      SafetyTone.idle => AlongIcon(AlongIcons.shield, size: 16, color: p.ink),
      SafetyTone.ok => AlongStrokeCheck(color: p.ink, size: 16),
      SafetyTone.waiting => AlongIcon(
        AlongIcons.schedule,
        size: 16,
        color: p.ink,
      ),
      SafetyTone.alarm => AlongIcon(AlongIcons.info, size: 16, color: p.danger),
    };
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: lead),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AlongType.body(p).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.25,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded live map of the trip with a frosted chip bottom-left.
class SafetyTripMap extends StatelessWidget {
  const SafetyTripMap({super.key, required this.trip, required this.chip});

  final TripSummary trip;
  final String chip;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final toPickup = trip.status == TripStatus.accepted;
    final driver = trip.live?.driver?.point;
    final from = toPickup
        ? (driver ?? trip.live?.rider?.point)
        : trip.board.location;
    final to = toPickup ? trip.board.location : trip.alight.location;
    return AlongCraft.clip(
      corner: AlongRadius.card.x,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VehicleMarkerPanel(
            from: from,
            to: to,
            vehicle: driver,
            modeCode: trip.modeCode,
            semanticLabel: trip.alight.name,
            topInset: 12,
            bottomInset: 48,
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: AlongElevation.float(p.ink)),
              child: AlongFrost(
                solid: true,
                radius: AlongRadius.control.x,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      chip,
                      style: AlongType.caption(p).copyWith(
                        color: p.ink,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contact face with name under it. [selected] draws an ink ring + check.
class SafetyContactFace extends StatelessWidget {
  const SafetyContactFace({
    super.key,
    required this.name,
    this.onTap,
    this.selected,
    this.size = 48,
  });

  final String name;
  final VoidCallback? onTap;
  final bool? selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final on = selected ?? false;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: size * 0.7,
        child: SizedBox(
          width: size + 24,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: on ? p.ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: AlongMonogram(
                      initials: safetyInitials(name),
                      size: size,
                      mark: 0.36,
                    ),
                  ),
                  if (on)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.bg, width: 2),
                        ),
                        child: AlongStrokeCheck(color: p.accentInk, size: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                safetyFirstName(name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AlongType.caption(p)
                    .copyWith(color: p.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed "add" face that matches [SafetyContactFace].
class SafetyAddFace extends StatelessWidget {
  const SafetyAddFace({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: SizedBox(
          width: 72,
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.recessed,
                  border: Border.all(color: p.line),
                ),
                child: AlongIcon(AlongIcons.plus, size: 20, color: p.ink),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AlongType.caption(p)
                    .copyWith(color: p.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

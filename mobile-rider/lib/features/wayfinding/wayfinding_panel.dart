import 'dart:io' show Platform;

import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/wayfinding/wayfinding_tts.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-19 wayfinding — text / map / audio segmented view.
class WayfindingPanel extends StatefulWidget {
  const WayfindingPanel({
    super.key,
    required this.directions,
    required this.mode,
    required this.onModeChanged,
    required this.tts,
    this.arrivedRadiusM,
    this.userLocation,
    this.destination,
    this.onArrived,
    this.drawnMap,
  });

  final WalkingDirections directions;
  final WayfindingMode mode;
  final ValueChanged<WayfindingMode> onModeChanged;
  final WayfindingTts tts;
  final int? arrivedRadiusM;
  final GeoPoint? userLocation;
  final GeoPoint? destination;
  final VoidCallback? onArrived;

  /// Paint a drawn street map instead of MapLibre. Null: drawn under
  /// `flutter test`, live basemap in the app.
  final bool? drawnMap;

  bool get _drawn => drawnMap ?? Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  State<WayfindingPanel> createState() => _WayfindingPanelState();
}

class _WayfindingPanelState extends State<WayfindingPanel> {
  var _audioPlaying = false;
  var _activeStepIndex = 0;

  @override
  void dispose() {
    widget.tts.stop();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WayfindingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkArrived();
  }

  void _checkArrived() {
    final radius = widget.arrivedRadiusM;
    final user = widget.userLocation;
    final dest = widget.destination;
    if (radius == null || user == null || dest == null) return;
    final distance = haversineDistanceM(user, dest);
    if (distance <= radius) {
      widget.onArrived?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeSwitch(
          mode: widget.mode,
          labels: {
            WayfindingMode.text: l10n.wayfindingModeText,
            WayfindingMode.map: l10n.wayfindingModeMap,
            WayfindingMode.audio: l10n.wayfindingModeAudio,
          },
          onChanged: (mode) {
            if (mode == widget.mode) return;
            if (_audioPlaying) {
              widget.tts.stop();
              setState(() => _audioPlaying = false);
            }
            widget.onModeChanged(mode);
          },
        ),
        const SizedBox(height: AlongSpace.s16),
        Expanded(child: _buildModeBody(context, l10n)),
      ],
    );
  }

  Widget _buildModeBody(BuildContext context, AppLocalizations l10n) {
    return switch (widget.mode) {
      WayfindingMode.text => _buildTextMode(l10n),
      WayfindingMode.map => _buildMapMode(l10n),
      WayfindingMode.audio => _buildAudioMode(l10n),
    };
  }

  Widget _currentStepCard(AppLocalizations l10n) {
    final p = AlongPalette.of(context);
    final steps = widget.directions.steps;
    if (steps.isEmpty) return const SizedBox.shrink();
    final i = _activeStepIndex.clamp(0, steps.length - 1);
    return DecoratedBox(
      key: const Key('wayfinding_here'),
      decoration: AlongCraft.compactFill(p.surface, 64, corner: 20),
      child: Padding(
        padding: const EdgeInsets.all(AlongSpace.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.accentInk, width: 1.5),
                  ),
                  child: const SizedBox(width: 14, height: 14),
                ),
                const SizedBox(width: AlongSpace.s8),
                Expanded(
                  child: Text(
                    l10n.wayfindingYouAreHere,
                    style: AlongType.label(p),
                  ),
                ),
                Text(
                  l10n.wayfindingStepOf(i + 1, steps.length),
                  style: AlongType.caption(p),
                ),
              ],
            ),
            const SizedBox(height: AlongSpace.s8),
            TripProgressBar(
              progress: (i + 0.5) / steps.length,
              from: steps[i].instruction,
              to: _formatDistance(widget.directions.distanceM),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMode(AppLocalizations l10n) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _currentStepCard(l10n),
        const SizedBox(height: AlongSpace.s12),
        StepList(
          playingLabel: l10n.wayfindingAudioPlaying,
          nowLabel: l10n.wayfindingNowPlaying,
          variant: StepListVariant.text,
          steps: [
            for (var i = 0; i < widget.directions.steps.length; i++)
              WayfindingStep(
                maneuverIcon: _iconForManeuver(
                  widget.directions.steps[i].maneuver,
                ),
                instruction: widget.directions.steps[i].instruction,
                distance: _formatDistance(widget.directions.steps[i].distanceM),
                isActive: i == _activeStepIndex,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapMode(AppLocalizations l10n) {
    final polyline = widget.directions.polyline;
    final camera = polyline.isNotEmpty ? polyline.first : widget.userLocation;
    return Stack(
      children: [
        KeyedSubtree(
          key: const Key('wayfinding_map'),
          child: AlongCraft.clip(
            corner: 20,
            child: widget._drawn
                ? CustomPaint(
                    painter: _WalkSketchPainter(
                      palette: AlongPalette.of(context),
                      polyline: polyline,
                      activeStep: _activeStepIndex,
                      stepCount: widget.directions.steps.length,
                    ),
                    child: const SizedBox.expand(),
                  )
                : AlongMap(
                    styleUrl: AlongStyleLoader.resolveBasemapStyleUrl(),
                    allowDemoStyleFallback: false,
                    initialCameraPosition: camera == null
                        ? null
                        : MapCamera.forCenter(
                            lat: camera.lat,
                            lng: camera.lng,
                            zoom: 16,
                          ),
                    onLayerControllerReady: (controller) {
                      controller.setWalkRoute(polyline);
                    },
                  ),
          ),
        ),
        Positioned(
          left: AlongSpace.s12,
          right: AlongSpace.s12,
          bottom: AlongSpace.s12,
          child: _currentStepCard(l10n),
        ),
        if (widget.directions.degraded)
          Positioned(
            top: AlongSpace.s8,
            left: AlongSpace.s8,
            right: AlongSpace.s8,
            child: DecoratedBox(
              decoration: AlongCraft.fill(
                AlongColors.semanticWarningTint,
                corner: 16,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AlongSpace.s12),
                child: Row(
                  children: [
                    const AlongIcon(
                      AlongIcons.info,
                      size: 20,
                      color: AlongColors.semanticWarning,
                    ),
                    const SizedBox(width: AlongSpace.s8),
                    Expanded(
                      child: Text(
                        l10n.wayfindingDegraded,
                        style: AlongText.caption.copyWith(
                          color: AlongColors.ink900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAudioMode(AppLocalizations l10n) {
    final script = widget.directions.ttsScript;
    final currentText = script.isNotEmpty && _activeStepIndex < script.length
        ? script[_activeStepIndex]
        : widget.directions.steps.isNotEmpty
        ? widget
              .directions
              .steps[_activeStepIndex.clamp(
                0,
                widget.directions.steps.length - 1,
              )]
              .instruction
        : l10n.wayfindingNoSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: StepList(
              playingLabel: l10n.wayfindingAudioPlaying,
              nowLabel: l10n.wayfindingNowPlaying,
              variant: _audioPlaying
                  ? StepListVariant.audioPlaying
                  : StepListVariant.text,
              steps: [
                for (var i = 0; i < widget.directions.steps.length; i++)
                  WayfindingStep(
                    maneuverIcon: _iconForManeuver(
                      widget.directions.steps[i].maneuver,
                    ),
                    instruction: widget.directions.steps[i].instruction,
                    distance: _formatDistance(
                      widget.directions.steps[i].distanceM,
                    ),
                    isActive: _audioPlaying && i == _activeStepIndex,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AlongSpace.s12),
        Builder(
          builder: (context) {
            final p = AlongPalette.of(context);
            return DecoratedBox(
              decoration: AlongCraft.compactFill(p.recessed, 64, corner: 20),
              child: Padding(
                padding: const EdgeInsets.all(AlongSpace.s12),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: _audioPlaying
                          ? l10n.wayfindingPause
                          : l10n.wayfindingPlay,
                      child: Material(
                        color: p.ink,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('wayfinding_audio_play'),
                          onTap: _toggleAudio,
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: Center(
                              child: Icon(
                                _audioPlaying
                                    ? AlongIcons.pause
                                    : AlongIcons.play,
                                size: 24,
                                color: p.onInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _audioPlaying
                                ? l10n.wayfindingPause
                                : l10n.wayfindingPlay,
                            style: AlongType.caption(p),
                          ),
                          Text(
                            currentText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AlongType.label(p),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _toggleAudio() async {
    if (_audioPlaying) {
      await widget.tts.stop();
      setState(() => _audioPlaying = false);
      return;
    }

    final script = widget.directions.ttsScript;
    final lines = script.isNotEmpty
        ? script
        : widget.directions.steps.map((s) => s.instruction).toList();
    if (lines.isEmpty) return;

    setState(() {
      _audioPlaying = true;
      _activeStepIndex = 0;
    });

    for (var i = 0; i < lines.length; i++) {
      if (!_audioPlaying) break;
      if (!mounted) return;
      setState(() => _activeStepIndex = i);
      await widget.tts.speak(lines[i]);
    }

    if (mounted) {
      setState(() => _audioPlaying = false);
    }
  }

  IconData _iconForManeuver(String? maneuver) => switch (maneuver) {
    'turn-left' || 'left' => AlongIcons.turnLeft,
    'turn-right' || 'right' => AlongIcons.turnRight,
    'arrive' => AlongIcons.flag,
    _ => AlongIcons.straight,
  };

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '$meters m';
  }
}

/// Three-way pill switch: Text, Map, Audio.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.mode,
    required this.labels,
    required this.onChanged,
  });

  final WayfindingMode mode;
  final Map<WayfindingMode, String> labels;
  final ValueChanged<WayfindingMode> onChanged;

  static const _icons = {
    WayfindingMode.text: AlongIcons.signpost,
    WayfindingMode.map: AlongIcons.map,
    WayfindingMode.audio: AlongIcons.speaker,
  };

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return DecoratedBox(
      decoration: AlongCraft.compactFill(p.recessed, 64, corner: 18),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (final m in WayfindingMode.values)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: m == mode,
                  child: Material(
                    color: m == mode ? p.ink : const Color(0x00000000),
                    shape: AlongCraft.border(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: Key('wayfinding_mode_${m.name}'),
                      onTap: () => onChanged(m),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AlongSpace.s4,
                            vertical: AlongSpace.s8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AlongIcon(
                                _icons[m]!,
                                size: 20,
                                color: m == mode ? p.onInk : p.ink,
                              ),
                              const SizedBox(width: AlongSpace.s4),
                              Flexible(
                                child: Text(
                                  labels[m]!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AlongType.label(p).copyWith(
                                    color: m == mode ? p.onInk : p.ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Drawn walk map for tests and previews: streets, the walk route, a dot
/// per step, the rider puck and a destination flag. Host-stable.
class _WalkSketchPainter extends CustomPainter {
  _WalkSketchPainter({
    required this.palette,
    required this.polyline,
    required this.activeStep,
    required this.stepCount,
  });

  final AlongPalette palette;
  final List<GeoPoint> polyline;
  final int activeStep;
  final int stepCount;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.mapLand);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.6,
        size.height * 0.08,
        size.width * 0.32,
        size.height * 0.2,
      ),
      Paint()..color = palette.mapPark,
    );
    final street = Paint()
      ..color = palette.mapRoad
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y - 12), Offset(size.width, y + 12), street);
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x + 10, 0), Offset(x - 10, size.height), street);
    }
    if (polyline.length < 2) return;
    var minLat = polyline.first.lat, maxLat = minLat;
    var minLng = polyline.first.lng, maxLng = minLng;
    for (final g in polyline) {
      if (g.lat < minLat) minLat = g.lat;
      if (g.lat > maxLat) maxLat = g.lat;
      if (g.lng < minLng) minLng = g.lng;
      if (g.lng > maxLng) maxLng = g.lng;
    }
    final box = Rect.fromLTRB(40, 48, size.width - 40, size.height - 150);
    final spanLat = (maxLat - minLat).abs() < 1e-9 ? 1e-9 : maxLat - minLat;
    final spanLng = (maxLng - minLng).abs() < 1e-9 ? 1e-9 : maxLng - minLng;
    Offset at(GeoPoint g) => Offset(
      box.left + (g.lng - minLng) / spanLng * box.width,
      box.bottom - (g.lat - minLat) / spanLat * box.height,
    );
    final pts = polyline.map(at).toList();
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    for (var i = 1; i < pts.length - 1; i++) {
      canvas.drawCircle(pts[i], 6, Paint()..color = palette.surface);
      canvas.drawCircle(
        pts[i],
        6,
        Paint()
          ..color = palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final end = pts.last;
    canvas.drawCircle(end, 12, Paint()..color = palette.ink);
    canvas.drawCircle(end, 5, Paint()..color = palette.onInk);
    final here = pts[activeStep.clamp(0, pts.length - 1)];
    canvas.drawCircle(
      here,
      20,
      Paint()..color = palette.accent.withValues(alpha: 0.28),
    );
    canvas.drawCircle(here, 9, Paint()..color = palette.accent);
    canvas.drawCircle(
      here,
      9,
      Paint()
        ..color = palette.accentInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _WalkSketchPainter old) =>
      old.activeStep != activeStep ||
      old.palette.brightness != palette.brightness ||
      old.polyline != polyline;
}

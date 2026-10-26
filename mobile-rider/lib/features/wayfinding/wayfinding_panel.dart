import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:along_map/along_map.dart';
import 'package:flutter/material.dart';
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
  });

  final WalkingDirections directions;
  final WayfindingMode mode;
  final ValueChanged<WayfindingMode> onModeChanged;
  final WayfindingTts tts;
  final int? arrivedRadiusM;
  final GeoPoint? userLocation;
  final GeoPoint? destination;
  final VoidCallback? onArrived;

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

  Widget _buildTextMode(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: StepList(
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
            corner: AlongRadius.card.x,
            child: AlongMap(
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

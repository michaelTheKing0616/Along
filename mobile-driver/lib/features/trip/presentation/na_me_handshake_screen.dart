import 'dart:async';

import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/trip/presentation/active_trip_controller.dart';
import 'package:mobile_driver/features/trip/presentation/na_me_camera_sampler.dart';

/// D-16 Board the rider: Na Me optical (camera) → tap-match → PIN.
class NaMeHandshakeScreen extends ConsumerStatefulWidget {
  const NaMeHandshakeScreen({
    super.key,
    required this.args,
    required this.riderName,
    required this.pairing,
  });

  final ActiveTripArgs args;
  final String riderName;
  final NaMePairing pairing;

  @override
  ConsumerState<NaMeHandshakeScreen> createState() =>
      _NaMeHandshakeScreenState();
}

class _NaMeHandshakeScreenState extends ConsumerState<NaMeHandshakeScreen> {
  List<AlongNaMeChoice>? _options;
  String? _secret;
  CameraController? _camera;
  final _proofs = StreamController<NaMeOpticalProof>.broadcast();
  final _decoder = NaMeOpticalDecoder();
  bool _ready = false;

  String get _tripId => widget.args.tripId;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final repo = ref.read(tripsRepositoryProvider);
    final optical = ref.read(appConfigProvider).naMeOpticalEnabled;
    try {
      final o = await repo.naMeTapOptions(_tripId);
      _options = [for (final p in o.options) _choice(p)];
    } catch (_) {
      _options = const [];
    }
    if (optical) {
      _secret = await repo.naMeSecret(_tripId);
      if (_secret != null) await _startCamera();
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _startCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await c.initialize();
      await c.startImageStream(_onFrame);
      _camera = c;
    } catch (_) {
      _camera = null; // No camera or no permission: tap-match.
    }
  }

  void _onFrame(CameraImage img) {
    final rgb = img.planes.length >= 3
        ? NaMeCameraSampler.centreRgbYuv(
            y: img.planes[0].bytes,
            u: img.planes[1].bytes,
            v: img.planes[2].bytes,
            width: img.width,
            height: img.height,
            yRowStride: img.planes[0].bytesPerRow,
            uvRowStride: img.planes[1].bytesPerRow,
            uvPixelStride: img.planes[1].bytesPerPixel ?? 1,
          )
        : NaMeCameraSampler.centreRgbBgra(
            bytes: img.planes[0].bytes,
            width: img.width,
            height: img.height,
            rowStride: img.planes[0].bytesPerRow,
          );
    final proof = _decoder.add(
      NaMeCameraSampler.normalise(rgb),
      DateTime.now(),
    );
    if (proof != null && !_proofs.isClosed) _proofs.add(proof);
  }

  @override
  void dispose() {
    final c = _camera;
    _camera = null;
    unawaited(_proofs.close());
    if (c != null) unawaited(c.dispose());
    super.dispose();
  }

  static AlongNaMeChoice _choice(NaMePairing p) =>
      AlongNaMeChoice(colorToken: p.colorToken, shape: p.shape, label: p.label);

  static AlongNaMeResult _result(NaMeMatchResult r) => AlongNaMeResult(
    r.matched
        ? AlongNaMeVerdict.matched
        : r.locked
        ? AlongNaMeVerdict.locked
        : r.rateLimited
        ? AlongNaMeVerdict.rateLimited
        : AlongNaMeVerdict.wrong,
    attemptsLeft: r.attemptsLeft,
    tapLocked: r.tapLocked,
  );

  /// Checked locally against the trip secret first: only a proof that is
  /// already right is sent, so misreads never burn an attempt, and the match
  /// shows even offline (the proof is queued and sent when back online).
  Future<AlongNaMeResult> _optical(NaMeOpticalProof proof) async {
    final secret = _secret;
    if (secret == null || NaMeOptical.code(secret, proof.step) != proof.code) {
      return const AlongNaMeResult(AlongNaMeVerdict.wrong);
    }
    await _camera?.stopImageStream().catchError((_) {});
    final repo = ref.read(tripsRepositoryProvider);
    try {
      final r = await repo.confirmNaMeMatch(_tripId, proof.toJson());
      if (r.matched) await _refresh();
      return _result(r);
    } catch (_) {
      await repo.queueNaMeProof(_tripId, proof.toJson());
      return const AlongNaMeResult(AlongNaMeVerdict.matched);
    }
  }

  Future<AlongNaMeResult> _tap(AlongNaMeChoice c) async {
    final r = await ref.read(tripsRepositoryProvider).confirmNaMeMatch(
      _tripId,
      {'method': 'tap', 'color_token': c.colorToken, 'shape': c.shape},
    );
    if (r.matched) await _refresh();
    return _result(r);
  }

  Future<void> _refresh() => ref
      .read(activeTripControllerFamilyProvider(widget.args).notifier)
      .refreshAfterBoarding()
      .catchError((_) {});

  Future<void> _chime() async {
    try {
      final player = AudioPlayer()..audioCache = AudioCache(prefix: '');
      await player.play(
        AssetSource('packages/along_design/assets/sounds/na_me_chime.wav'),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        backgroundColor: AlongPalette.of(context).bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final controller = ref.read(
      activeTripControllerFamilyProvider(widget.args).notifier,
    );
    final camera = _camera;
    final options = _options!;
    return AlongNaMeDriverFlow(
      riderName: widget.riderName,
      pairing: _choice(widget.pairing),
      options: options,
      cameraPreview: camera == null ? null : CameraPreview(camera),
      opticalProofs: camera == null ? null : _proofs.stream,
      onOptical: camera == null ? null : _optical,
      onTap: _tap,
      onPin: controller.verifyPin,
      onChime: _chime,
      onStart: () async {
        final nav = Navigator.of(context);
        await controller.startTrip();
        nav.maybePop();
      },
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:along_core/along_core.dart' show TripSummary;
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_rider/features/safety/presentation/sos_active_screen.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';
import 'package:permission_handler/permission_handler.dart';

/// Forces a screen state in widget tests. A live camera is never opened.
enum PlateScanDebugView { denied, scanning, match, mismatch }

class PlateScanArgs {
  const PlateScanArgs({
    required this.expectedPlate,
    this.tripId,
    this.trip,
    this.debugView,
  });

  final String expectedPlate;
  final String? tripId;
  final TripSummary? trip;
  final PlateScanDebugView? debugView;
}

/// Live viewfinder that reads a Nigerian plate on the phone.
///
/// Frames stay in memory. The log stores only match or mismatch.
class PlateScanScreen extends StatefulWidget {
  const PlateScanScreen({super.key, required this.args});

  final PlateScanArgs args;

  @override
  State<PlateScanScreen> createState() => _PlateScanScreenState();
}

class _PlateScanScreenState extends State<PlateScanScreen> {
  static const _frameThrottle = Duration(milliseconds: 800);

  CameraController? _camera;
  TextRecognizer? _recognizer;
  PlateMatchKind? _kind;
  var _denied = false;
  var _opening = false;
  var _torch = false;
  var _busy = false;
  var _closed = false;
  DateTime? _lastFrame;

  bool get _inFlutterTest => Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  void initState() {
    super.initState();
    final view = widget.args.debugView;
    if (view == PlateScanDebugView.match ||
        view == PlateScanDebugView.mismatch) {
      final kind = view == PlateScanDebugView.match
          ? PlateMatchKind.match
          : PlateMatchKind.mismatch;
      _kind = kind;
      PlateScanLog.record(kind);
      return;
    }
    if (view == PlateScanDebugView.scanning) return;
    if (view == PlateScanDebugView.denied || _inFlutterTest) {
      _denied = true;
      return;
    }
    _opening = true;
    unawaited(_openCamera());
  }

  @override
  void dispose() {
    _closed = true;
    final camera = _camera;
    _camera = null;
    if (camera != null) {
      if (camera.value.isStreamingImages) {
        camera.stopImageStream().whenComplete(camera.dispose);
      } else {
        camera.dispose();
      }
    }
    _recognizer?.close();
    _recognizer = null;
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showDenied();
        return;
      }
      final cameras = await availableCameras();
      if (cameras.isEmpty || _closed) {
        _showDenied();
        return;
      }
      final camera = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await camera.initialize();
      if (_closed) {
        await camera.dispose();
        return;
      }
      _camera = camera;
      _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      await camera.startImageStream(_onFrame);
      if (mounted) {
        setState(() => _opening = false);
      }
    } catch (_) {
      _showDenied();
    }
  }

  void _showDenied() {
    if (!mounted || _closed) return;
    setState(() {
      _denied = true;
      _opening = false;
    });
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_closed || _kind != null || _busy) return;
    final now = DateTime.now();
    final last = _lastFrame;
    if (last != null && now.difference(last) < _frameThrottle) return;
    final camera = _camera;
    final recognizer = _recognizer;
    if (camera == null || recognizer == null) return;
    final input = _inputImage(image, camera.description);
    if (input == null) return;
    _lastFrame = now;
    _busy = true;
    try {
      final recognized = await recognizer.processImage(input);
      if (_closed || _kind != null) return;
      final judgement = judgePlateReading(
        ocrText: recognized.text,
        expectedPlate: widget.args.expectedPlate,
      );
      if (judgement == null) return;
      await _settle(judgement.kind);
    } catch (_) {
      // A bad frame stays on the viewfinder.
    } finally {
      _busy = false;
    }
  }

  Future<void> _settle(PlateMatchKind kind) async {
    if (_closed || _kind != null) return;
    PlateScanLog.record(kind);
    final camera = _camera;
    if (camera != null && camera.value.isStreamingImages) {
      await camera.stopImageStream();
    }
    if (!mounted || _closed) return;
    setState(() => _kind = kind);
  }

  Future<void> _toggleTorch() async {
    final next = !_torch;
    setState(() => _torch = next);
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      await camera.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      if (mounted) setState(() => _torch = !next);
    }
  }

  void _confirm() => context.pop(true);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kind = _kind;
    if (_denied) return _deniedView(l10n);
    if (kind == PlateMatchKind.match) return _matchView(l10n);
    if (kind == PlateMatchKind.mismatch) return _mismatchView(l10n);
    return _scanner(l10n);
  }

  Widget _deniedView(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.plateScan)),
      body: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.plateScanDenied,
              key: const Key('plate_scan_denied'),
              style: AlongText.body,
            ),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('plate_scan_confirm'),
              label: l10n.plateCheck,
              variant: AlongButtonVariant.yellow,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchView(AppLocalizations l10n) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.plateScan)),
      body: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.plateMatches,
              key: const Key('plate_scan_match'),
              style: AlongText.heading2.copyWith(
                color: AlongColors.semanticSuccess,
              ),
            ),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('plate_scan_continue'),
              label: l10n.plateScanContinue,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mismatchView(AppLocalizations l10n) {
    final trip = widget.args.trip;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.plateScan)),
      body: Padding(
        padding: const EdgeInsets.all(AlongSpace.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.plateScanMismatch,
              key: const Key('plate_scan_mismatch'),
              style: AlongText.bodyStrong.copyWith(
                color: AlongColors.semanticWarning,
              ),
            ),
            const SizedBox(height: AlongSpace.s16),
            AlongButton(
              key: const Key('plate_scan_report'),
              label: l10n.plateScanReport,
              variant: AlongButtonVariant.secondary,
              onPressed: () => context.push(
                AppRoutes.reportIncident,
                extra: widget.args.tripId,
              ),
            ),
            if (trip != null) ...[
              const SizedBox(height: AlongSpace.s8),
              AlongButton(
                key: const Key('plate_scan_sos'),
                label: l10n.plateScanSos,
                variant: AlongButtonVariant.danger,
                onPressed: () => context.push(
                  AppRoutes.sosActive,
                  extra: SosActiveRouteArgs(trip: trip),
                ),
              ),
            ],
            const SizedBox(height: AlongSpace.s8),
            AlongButton(
              key: const Key('plate_scan_confirm'),
              label: l10n.plateCheck,
              variant: AlongButtonVariant.yellow,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanner(AppLocalizations l10n) {
    final camera = _camera;
    final ready = camera != null && camera.value.isInitialized;
    return Scaffold(
      backgroundColor: AlongColors.ink900,
      appBar: AppBar(
        backgroundColor: AlongColors.ink900,
        foregroundColor: AlongColors.surface0,
        title: Text(l10n.plateScan),
        actions: [
          IconButton(
            key: const Key('plate_scan_torch'),
            tooltip: l10n.plateScanTorch,
            onPressed: _toggleTorch,
            icon: Icon(
              _torch ? Icons.flashlight_on : Icons.flashlight_off,
              color: AlongColors.brandYellow,
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready) CameraPreview(camera),
          Center(
            child: Container(
              key: const Key('plate_scan_frame'),
              width: 280,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AlongColors.surface0, width: 3),
                borderRadius: BorderRadius.circular(AlongRadius.sm.x),
              ),
              child: ready || !_opening
                  ? null
                  : const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(AlongSpace.s16),
              child: Text(
                l10n.plateScanHint,
                key: const Key('plate_scan_hint'),
                style: AlongText.body.copyWith(color: AlongColors.surface0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputImage? _inputImage(CameraImage image, CameraDescription description) {
  final rotation = InputImageRotationValue.fromRawValue(
    description.sensorOrientation,
  );
  if (rotation == null || image.planes.isEmpty) return null;
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;
  final plane = image.planes.first;
  final androidNv21 =
      format == InputImageFormat.nv21 && image.planes.length == 1;
  final iosBgra =
      format == InputImageFormat.bgra8888 && image.planes.length == 1;
  if (!androidNv21 && !iosBgra) return null;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}

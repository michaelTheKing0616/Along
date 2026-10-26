import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/payments/data/payments_providers.dart';
import 'package:mobile_rider/features/payments/domain/qr_payload_parser.dart';
import 'package:mobile_rider/features/payments/domain/qr_scanner_port.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-31 Scan to pay — camera placeholder, torch, typed code entry.
class ScanToPayScreen extends ConsumerStatefulWidget {
  const ScanToPayScreen({super.key, this.debugFound = false});

  /// Golden hook: render the lock-on state without a real scan.
  final bool debugFound;

  @override
  ConsumerState<ScanToPayScreen> createState() => _ScanToPayScreenState();
}

class _ScanToPayScreenState extends ConsumerState<ScanToPayScreen> {
  StreamSubscription<String>? _scanSub;
  QrScannerPort? _scanner;
  bool _torchOn = false;
  bool _showTypedEntry = false;
  final _codeController = TextEditingController();
  String? _rejectMessage;
  late bool _found = widget.debugFound;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    _startScanner();
  }

  Future<void> _startScanner() async {
    _scanner = ref.read(qrScannerProvider);
    await _scanner!.start();
    _scanSub = _scanner!.scans.listen(_onScan);
  }

  Future<void> _onScan(String payload) async {
    final code = QrPayloadParser.parse(payload);
    if (code == null) {
      setState(
        () => _rejectMessage = AppLocalizations.of(context).scanNotAlong,
      );
      return;
    }
    setState(() {
      _rejectMessage = null;
      _found = true;
    });
    await _openPaySheet(code, payload);
    if (mounted) setState(() => _found = false);
  }

  Future<void> _openPaySheet(String code, String rawPayload) async {
    Uri? uri;
    try {
      uri = Uri.parse(rawPayload.trim());
    } catch (_) {}

    final token = uri?.queryParameters['t'];
    QrResolveResult? resolved;
    try {
      resolved = await ref
          .read(paymentsRepositoryProvider)
          .resolveQr(driverCode: code, token: token);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _rejectMessage = AppLocalizations.of(context).scanNotAlong,
      );
      return;
    }

    if (!mounted) return;
    await PayDriverSheet.show(
      context,
      driverCode: code,
      dynamicToken: token,
      preloadedResolve: resolved,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _onCodeChanged() {
    if (mounted) setState(() => _rejectMessage = null);
  }

  /// Continue is live only once the typed text is a valid driver code.
  String? get _typedCode =>
      QrPayloadParser.parse(_codeController.text) ??
      QrPayloadParser.parse('along://p/${_codeController.text.trim()}');

  bool get _typedValid => _typedCode != null;

  Future<void> _submitTypedCode() async {
    if (!_typedValid) return;
    final normalised =
        QrPayloadParser.parse(_codeController.text) ??
        QrPayloadParser.parse('along://p/${_codeController.text}');
    if (normalised == null) {
      setState(
        () => _rejectMessage = AppLocalizations.of(context).scanNotAlong,
      );
      return;
    }
    await _openPaySheet(normalised, 'along://p/$normalised');
  }

  Future<void> _toggleTorch() async {
    _torchOn = !_torchOn;
    await _scanner?.setTorch(_torchOn);
    setState(() {});
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _codeController.dispose();
    _scanner?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _showTypedEntry ? _typedEntry(l10n) : _cameraView(l10n);
  }

  Widget _cameraView(AppLocalizations l10n) {
    const fg = AlongColors.surface0;
    return RiderTripStrings(
      child: Scaffold(
        backgroundColor: AlongColors.ink900,
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
                    if (Navigator.of(context).canPop())
                      AlongMapButton(
                        key: const Key('scan_back'),
                        icon: AlongIcons.back,
                        tooltip: MaterialLocalizations.of(context)
                            .backButtonTooltip,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s20,
                  AlongSpace.s16,
                  AlongSpace.s20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scanToPayTitle,
                      style: AlongText.displayL.copyWith(color: fg),
                    ),
                    const SizedBox(height: AlongSpace.s4),
                    Text(
                      l10n.scanToPayHint,
                      style: AlongText.body.copyWith(
                        color: fg.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(
                        key: Key('scan_camera_view'),
                        painter: _ScenePainter(),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: _found ? 0.92 : 1,
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: SizedBox(
                              key: const Key('scan_frame'),
                              width: 248,
                              height: 248,
                              child: CustomPaint(
                                painter: _FramePainter(
                                  color: _found
                                      ? AlongColors.semanticSuccessFill
                                      : AlongColors.brandYellow,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AlongSpace.s20),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AlongSpace.s20,
                            ),
                            child: _plate(l10n),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AlongSpace.s20,
                  AlongSpace.s8,
                  AlongSpace.s20,
                  AlongSpace.s12,
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      toggled: _torchOn,
                      label: l10n.scanTorch,
                      child: Material(
                        color: _torchOn
                            ? AlongColors.brandYellow
                            : fg.withValues(alpha: 0.12),
                        shape: AlongCraft.border(18),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const Key('scan_torch_toggle'),
                          onTap: _toggleTorch,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: AlongIcon(
                                AlongIcons.torch,
                                size: 24,
                                color: _torchOn ? AlongColors.ink900 : fg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AlongSpace.s12),
                    Expanded(
                      child: AlongButton(
                        key: const Key('scan_enter_code'),
                        label: l10n.scanEnterCode,
                        variant: AlongButtonVariant.yellow,
                        onPressed: () => setState(() {
                          _rejectMessage = null;
                          _showTypedEntry = true;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plate(AppLocalizations l10n) {
    final reject = _rejectMessage;
    final (Color bg, Color fg, IconData icon, String text, Key? key) = _found
        ? (
            AlongColors.semanticSuccessFill,
            AlongColors.surface0,
            AlongIcons.check,
            l10n.scanFound,
            const Key('scan_found'),
          )
        : reject != null
        ? (
            AlongColors.semanticWarningTint,
            AlongColors.ink900,
            AlongIcons.info,
            reject,
            const Key('scan_reject_message'),
          )
        : (
            AlongColors.surface0.withValues(alpha: 0.14),
            AlongColors.surface0,
            AlongIcons.qrCode,
            l10n.scanFitHint,
            null,
          );
    return DecoratedBox(
      key: key,
      decoration: AlongCraft.fill(bg, corner: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AlongSpace.s16,
          vertical: AlongSpace.s12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlongIcon(icon, size: 20, color: fg),
            const SizedBox(width: AlongSpace.s8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: AlongText.bodyStrong.copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typedEntry(AppLocalizations l10n) {
    final p = AlongPalette.of(context);
    return TripPage(
      title: l10n.scanEnterCodePrompt,
      subtitle: l10n.scanCodeHint,
      onBack: () => setState(() {
        _rejectMessage = null;
        _showTypedEntry = false;
      }),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AlongButton(
            key: const Key('scan_code_submit'),
            label: l10n.scanCodeSubmit,
            onPressed: _typedValid ? _submitTypedCode : null,
          ),
          const SizedBox(height: AlongSpace.s4),
          AlongButton(
            key: const Key('scan_back_to_camera'),
            label: l10n.scanBackToCamera,
            variant: AlongButtonVariant.tertiary,
            onPressed: () => setState(() {
              _rejectMessage = null;
              _showTypedEntry = false;
            }),
          ),
        ],
      ),
      children: [
        TextField(
          key: const Key('scan_code_field'),
          controller: _codeController,
          maxLength: 8,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: AlongType.numeric(p).copyWith(letterSpacing: 4),
          decoration: tripInputDecoration(
            p,
            hint: 'ABC12345',
          ).copyWith(counterText: ''),
          onSubmitted: (_) => _submitTypedCode(),
        ),
        if (_rejectMessage != null) ...[
          const SizedBox(height: AlongSpace.s12),
          TripNotice(
            key: const Key('scan_reject_message'),
            icon: AlongIcons.info,
            text: _rejectMessage!,
            warn: true,
          ),
        ],
        const SizedBox(height: AlongSpace.s20),
        TripPanel(
          key: const Key('scan_code_where'),
          child: Row(
            children: [
              DecoratedBox(
                decoration: AlongCraft.compactFill(
                  AlongColors.brandYellow,
                  88,
                  corner: 16,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AlongSpace.s8),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AlongColors.surface0,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const CustomPaint(painter: _MiniQrPainter()),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ABC12345',
                        style: AlongType.caption(
                          p,
                        ).copyWith(color: AlongColors.ink900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AlongSpace.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.scanCodeWhereTitle, style: AlongType.label(p)),
                    const SizedBox(height: 2),
                    Text(l10n.scanCodeWhereBody, style: AlongType.caption(p)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tiny QR glyph for the "where to find it" helper.
class _MiniQrPainter extends CustomPainter {
  const _MiniQrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const n = 9;
    final unit = size.width / n;
    final paint = Paint()..color = AlongColors.ink900;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final finder = (x < 3 && y < 3) || (x > 5 && y < 3) || (x < 3 && y > 5);
        if (finder || (x * 7 + y * 3) % 5 < 2) {
          canvas.drawRect(
            Rect.fromLTWH(x * unit, y * unit, unit - 0.6, unit - 0.6),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniQrPainter oldDelegate) => false;
}

/// Four yellow corner brackets: the viewfinder.
class _FramePainter extends CustomPainter {
  const _FramePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = (Offset.zero & size).center;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      Paint()..color = AlongColors.surface0.withValues(alpha: 0.04),
    );
    final sticker = Rect.fromCenter(center: c, width: 176, height: 176);
    canvas.drawRRect(
      RRect.fromRectAndRadius(sticker, const Radius.circular(20)),
      Paint()..color = AlongColors.brandYellow.withValues(alpha: 0.16),
    );
    final cell = Paint()..color = AlongColors.surface0.withValues(alpha: 0.10);
    const n = 9;
    final unit = 136 / n;
    final origin = sticker.topLeft + const Offset(20, 20);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final finder = (x < 3 && y < 3) || (x > 5 && y < 3) || (x < 3 && y > 5);
        if (finder || (x * 7 + y * 3) % 5 < 2) {
          canvas.drawRect(
            Rect.fromLTWH(
              origin.dx + x * unit,
              origin.dy + y * unit,
              unit - 2,
              unit - 2,
            ),
            cell,
          );
        }
      }
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const arm = 44.0;
    const r = 20.0;
    final w = size.width;
    final h = size.height;
    void corner(Offset o, double sx, double sy) {
      final path = Path()
        ..moveTo(o.dx, o.dy + sy * arm)
        ..lineTo(o.dx, o.dy + sy * r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + sx * r, o.dy)
        ..lineTo(o.dx + sx * arm, o.dy);
      canvas.drawPath(path, paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(w, 0), -1, 1);
    corner(Offset(0, h), 1, -1);
    corner(Offset(w, h), -1, -1);
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.color != color;
}

/// Dimmed camera look: a dusk vignette and an out-of-focus dashboard.
class _ScenePainter extends CustomPainter {
  const _ScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.1),
          radius: 0.9,
          colors: [Color(0xFF3A342B), Color(0xFF1C1915), AlongColors.ink900],
          stops: [0, 0.45, 0.8],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, size.height * 0.84, size.width + 40, size.height),
        const Radius.circular(48),
      ),
      Paint()..color = const Color(0x33000000),
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => false;
}

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
  const ScanToPayScreen({super.key});

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

  @override
  void initState() {
    super.initState();
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
    await _openPaySheet(code, payload);
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

  Future<void> _submitTypedCode() async {
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
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(
                        key: Key('scan_camera_view'),
                        color: AlongColors.ink900,
                      ),
                    ),
                    const SizedBox(
                      key: Key('scan_frame'),
                      width: 248,
                      height: 248,
                      child: CustomPaint(painter: _FramePainter()),
                    ),
                    if (_rejectMessage != null)
                      Positioned(
                        bottom: AlongSpace.s16,
                        left: AlongSpace.s20,
                        right: AlongSpace.s20,
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
                                    key: const Key('scan_reject_message'),
                                    _rejectMessage!,
                                    style: AlongText.bodyStrong.copyWith(
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
            onPressed: _submitTypedCode,
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
      ],
    );
  }
}

/// Four yellow corner brackets: the viewfinder.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlongColors.brandYellow
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

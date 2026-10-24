import 'dart:async';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/features/live_trip/presentation/pay_driver_sheet.dart';
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
      setState(() => _rejectMessage = AppLocalizations.of(context).scanNotAlong);
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
      resolved = await ref.read(paymentsRepositoryProvider).resolveQr(
            driverCode: code,
            token: token,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _rejectMessage = AppLocalizations.of(context).scanNotAlong);
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
    final normalised = QrPayloadParser.parse(_codeController.text) ??
        QrPayloadParser.parse('along://p/${_codeController.text}');
    if (normalised == null) {
      setState(() => _rejectMessage = AppLocalizations.of(context).scanNotAlong);
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

    return Scaffold(
      backgroundColor: AlongColors.ink900,
      appBar: AppBar(
        title: Text(l10n.scanToPayTitle),
        backgroundColor: AlongColors.ink900,
        foregroundColor: AlongColors.surface0,
      ),
      body: _showTypedEntry ? _typedEntry(l10n) : _cameraView(l10n),
    );
  }

  Widget _cameraView(AppLocalizations l10n) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                key: const Key('scan_camera_view'),
                color: AlongColors.ink900,
                width: double.infinity,
              ),
              Container(
                width: 240,
                height: 240,
                decoration: AlongCraft.fill(
                  const Color(0x00000000),
                  corner: AlongRadius.card.x,
                  side: const BorderSide(
                    color: AlongColors.brandYellow,
                    width: 2,
                  ),
                ),
              ),
              if (_rejectMessage != null)
                Positioned(
                  bottom: AlongSpace.s24,
                  left: AlongSpace.s16,
                  right: AlongSpace.s16,
                  child: Text(
                    key: const Key('scan_reject_message'),
                    _rejectMessage!,
                    textAlign: TextAlign.center,
                    style: AlongText.body.copyWith(color: AlongColors.brandYellow),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AlongSpace.s16),
          child: Row(
            children: [
              IconButton(
                key: const Key('scan_torch_toggle'),
                onPressed: _toggleTorch,
                icon: Icon(
                  _torchOn ? Icons.flash_on : Icons.flash_off,
                  color: AlongColors.brandYellow,
                ),
              ),
              Expanded(
                child: AlongButton(
                  key: const Key('scan_enter_code'),
                  label: l10n.scanEnterCode,
                  variant: AlongButtonVariant.secondary,
                  onPressed: () => setState(() => _showTypedEntry = true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _typedEntry(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AlongSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.scanEnterCodePrompt, style: AlongText.heading2),
          const SizedBox(height: AlongSpace.s16),
          TextField(
            key: const Key('scan_code_field'),
            controller: _codeController,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              counterText: '',
              hintText: l10n.scanCodeHint,
            ),
          ),
          if (_rejectMessage != null) ...[
            const SizedBox(height: AlongSpace.s8),
            Text(
              _rejectMessage!,
              style: AlongText.caption.copyWith(color: AlongColors.semanticDanger),
            ),
          ],
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('scan_code_submit'),
            label: l10n.scanCodeSubmit,
            variant: AlongButtonVariant.yellow,
            onPressed: _submitTypedCode,
          ),
          TextButton(
            onPressed: () => setState(() => _showTypedEntry = false),
            child: Text(l10n.scanBackToCamera),
          ),
        ],
      ),
    );
  }
}

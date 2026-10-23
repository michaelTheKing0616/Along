import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// D-22 Guarantor registration (doc 06).
class GuarantorScreen extends ConsumerStatefulWidget {
  const GuarantorScreen({super.key});

  @override
  ConsumerState<GuarantorScreen> createState() => _GuarantorScreenState();
}

class _GuarantorScreenState extends ConsumerState<GuarantorScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _type = 'fellow_driver';
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(ledgerRepositoryProvider).registerGuarantor(
            guarantorType: _type,
            name: _nameController.text.trim(),
            phoneE164: _phoneController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _message = AppLocalizations.of(context).guarantorSuccess;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = AppLocalizations.of(context).errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      key: const Key('guarantor_screen'),
      appBar: AppBar(
        title: Text(l10n.guarantorTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          Text(l10n.guarantorExplainer, style: AlongText.body),
          const SizedBox(height: AlongSpace.s16),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'fellow_driver',
                label: Text(l10n.guarantorTypeDriver),
              ),
              ButtonSegment(
                value: 'vehicle_owner',
                label: Text(l10n.guarantorTypeOwner),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: AlongSpace.s16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.guarantorNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.guarantorPhoneLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AlongSpace.s16),
          AlongButton(
            key: const Key('guarantor_submit'),
            label: l10n.guarantorSubmit,
            visualState:
                _busy ? AlongButtonVisualState.loading : AlongButtonVisualState.normal,
            onPressed: _busy ? null : _submit,
          ),
          if (_message != null) ...[
            const SizedBox(height: AlongSpace.s12),
            Text(_message!, style: AlongText.bodyStrong),
          ],
        ],
      ),
    );
  }
}

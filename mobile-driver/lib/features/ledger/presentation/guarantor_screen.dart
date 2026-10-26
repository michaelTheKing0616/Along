import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

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
      await ref
          .read(ledgerRepositoryProvider)
          .registerGuarantor(
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

    final p = AlongPalette.of(context);
    InputDecoration field(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: p.recessed,
      border: AlongCraft.input(BorderSide.none),
      enabledBorder: AlongCraft.input(BorderSide.none),
      focusedBorder: AlongCraft.input(BorderSide(color: p.ink, width: 1.5)),
    );
    return KeyedSubtree(
      key: const Key('guarantor_screen'),
      child: DrivePage(
        title: l10n.guarantorTitle,
        subtitle: l10n.guarantorExplainer,
        footer: AlongButton(
          key: const Key('guarantor_submit'),
          label: l10n.guarantorSubmit,
          visualState: _busy
              ? AlongButtonVisualState.loading
              : AlongButtonVisualState.normal,
          onPressed: _busy ? null : _submit,
        ),
        children: [
          DriveSection(l10n.guarantorWhoTitle),
          DriveRows(
            children: [
              DriveRow(
                key: const Key('guarantor_type_driver'),
                icon: AlongIcons.user,
                title: l10n.guarantorTypeDriver,
                selected: _type == 'fellow_driver',
                onTap: () => setState(() => _type = 'fellow_driver'),
              ),
              DriveRow(
                key: const Key('guarantor_type_owner'),
                icon: AlongIcons.danfo,
                title: l10n.guarantorTypeOwner,
                selected: _type == 'vehicle_owner',
                onTap: () => setState(() => _type = 'vehicle_owner'),
              ),
            ],
          ),
          DriveSection(l10n.guarantorDetailsTitle),
          TextField(
            key: const Key('guarantor_name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: field(l10n.guarantorNameLabel),
          ),
          const SizedBox(height: AlongSpace.s12),
          TextField(
            key: const Key('guarantor_phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: field(l10n.guarantorPhoneLabel),
          ),
          if (_message != null) ...[
            const SizedBox(height: AlongSpace.s12),
            Text(_message!, style: AlongType.label(p)),
          ],
        ],
      ),
    );
  }
}

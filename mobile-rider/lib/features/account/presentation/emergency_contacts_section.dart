import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Owner-managed people notified when this account raises SOS.
class EmergencyContactsSection extends ConsumerStatefulWidget {
  const EmergencyContactsSection({super.key});

  @override
  ConsumerState<EmergencyContactsSection> createState() =>
      _EmergencyContactsSectionState();
}

class _EmergencyContactsSectionState
    extends ConsumerState<EmergencyContactsSection> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  List<EmergencyContact> _contacts = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = ref.read(emergencyContactStoreProvider);
    try {
      final contacts = await ref
          .read(safetyRepositoryProvider)
          .listEmergencyContacts();
      await store.write(contacts);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      try {
        final cached = await store.read();
        if (!mounted) return;
        setState(() {
          _contacts = cached;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final phone = normalizeEmergencyPhone(_phoneController.text);
    if (name.isEmpty || phone == null) {
      setState(() => _error = l10n.emergencyContactInvalidPhone);
      return;
    }
    if (_contacts.length >= emergencyContactLimit) {
      setState(() => _error = l10n.emergencyContactLimit);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(safetyRepositoryProvider)
          .upsertEmergencyContact(name: name, phoneE164: phone);
      _nameController.clear();
      _phoneController.clear();
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.emergencyContactSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(EmergencyContact contact) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(safetyRepositoryProvider)
          .deleteEmergencyContact(contact.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = l10n.emergencyContactSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final atLimit = _contacts.length >= emergencyContactLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.emergencyContactsHeading, style: AlongText.overline),
        const SizedBox(height: AlongSpace.s8),
        Text(l10n.emergencyContactsHint, style: AlongText.caption),
        const SizedBox(height: AlongSpace.s12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AlongSpace.s8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_contacts.isEmpty)
          Text(l10n.emergencyContactsEmpty, style: AlongText.body)
        else
          for (final contact in _contacts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(contact.name, style: AlongText.bodyStrong),
              subtitle: Text(contact.phoneE164, style: AlongText.caption),
              trailing: IconButton(
                tooltip: l10n.emergencyContactRemove(contact.name),
                onPressed: _saving ? null : () => _remove(contact),
                icon: const Icon(Icons.close),
              ),
            ),
        if (!atLimit) ...[
          const SizedBox(height: AlongSpace.s8),
          TextField(
            key: const Key('emergency_contact_name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.emergencyContactName),
          ),
          const SizedBox(height: AlongSpace.s8),
          TextField(
            key: const Key('emergency_contact_phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.emergencyContactPhone,
              hintText: '+2348012345678',
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          AlongButton(
            key: const Key('emergency_contact_add'),
            label: l10n.emergencyContactAdd,
            variant: AlongButtonVariant.secondary,
            onPressed: _saving ? null : _add,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AlongSpace.s8),
          Text(
            _error!,
            style: AlongText.caption.copyWith(
              color: AlongColors.semanticDanger,
            ),
          ),
        ],
      ],
    );
  }
}

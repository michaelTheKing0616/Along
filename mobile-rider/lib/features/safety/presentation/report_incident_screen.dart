import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/safety/domain/incident_categories.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-24 Report incident — category grid, description, optional photo stub.
class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({
    super.key,
    this.tripId,
  });

  final String? tripId;

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  String? _selectedType;
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _photoStubPath;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final type = _selectedType;
    final description = _descriptionController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportIncidentPickCategory)),
      );
      return;
    }
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportIncidentDescriptionRequired)),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(safetyRepositoryProvider).reportIncident(
            tripId: widget.tripId,
            type: type,
            description: description,
            attachmentPaths:
                _photoStubPath == null ? const [] : [_photoStubPath!],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportIncidentSubmitted)),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  IconData _iconFor(String iconName) => switch (iconName) {
        'shield' => Icons.shield_outlined,
        'payments' => Icons.payments_outlined,
        'directions_car' => Icons.directions_car_outlined,
        'person' => Icons.person_outline,
        'inventory_2' => Icons.inventory_2_outlined,
        _ => Icons.more_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportIncidentTitle),
        backgroundColor: AlongColors.surface0,
        foregroundColor: AlongColors.ink900,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AlongSpace.s16),
        children: [
          Text(l10n.reportIncidentCategoryHeading, style: AlongText.heading2),
          const SizedBox(height: AlongSpace.s12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AlongSpace.s8,
            crossAxisSpacing: AlongSpace.s8,
            childAspectRatio: 1.4,
            children: [
              for (final category in incidentCategories)
                _CategoryTile(
                  key: Key('incident_category_${category.type}'),
                  label: incidentCategoryLabel(
                    category.type,
                    (key) => _l10nKey(l10n, key),
                  ),
                  icon: _iconFor(category.iconName),
                  selected: _selectedType == category.type,
                  onTap: () => setState(() => _selectedType = category.type),
                ),
            ],
          ),
          const SizedBox(height: AlongSpace.s24),
          Text(l10n.reportIncidentDescriptionHeading, style: AlongText.heading2),
          const SizedBox(height: AlongSpace.s8),
          TextField(
            key: const Key('report_incident_description'),
            controller: _descriptionController,
            maxLength: 2000,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: l10n.reportIncidentDescriptionHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AlongRadius.sm.x),
              ),
            ),
          ),
          const SizedBox(height: AlongSpace.s12),
          AlongButton(
            key: const Key('report_incident_attach'),
            label: _photoStubPath == null
                ? l10n.reportIncidentAttachPhoto
                : l10n.reportIncidentPhotoAttached,
            variant: AlongButtonVariant.secondary,
            onPressed: () => setState(
              () => _photoStubPath = 'stub/incident-photo.jpg',
            ),
          ),
          const SizedBox(height: AlongSpace.s24),
          AlongButton(
            key: const Key('report_incident_submit'),
            label: l10n.reportIncidentSubmit,
            visualState: _submitting
                ? AlongButtonVisualState.loading
                : AlongButtonVisualState.normal,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  String _l10nKey(AppLocalizations l10n, String key) => switch (key) {
        'incidentCategorySafety' => l10n.incidentCategorySafety,
        'incidentCategoryFareDispute' => l10n.incidentCategoryFareDispute,
        'incidentCategoryVehicleQuality' => l10n.incidentCategoryVehicleQuality,
        'incidentCategoryDriverBehavior' => l10n.incidentCategoryDriverBehavior,
        'incidentCategoryLostItem' => l10n.incidentCategoryLostItem,
        'incidentCategoryOther' => l10n.incidentCategoryOther,
        _ => key,
      };
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AlongColors.brandYellowTint : AlongColors.surface100,
      borderRadius: BorderRadius.circular(AlongRadius.md.x),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AlongRadius.md.x),
        child: Padding(
          padding: const EdgeInsets.all(AlongSpace.s12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AlongColors.ink900 : AlongColors.ink700,
              ),
              const SizedBox(height: AlongSpace.s8),
              Text(
                label,
                style: AlongText.label,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

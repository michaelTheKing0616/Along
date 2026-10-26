import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/safety/domain/incident_categories.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-24 Report incident — category grid, description, optional photo stub.
class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key, this.tripId});

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.reportIncidentPickCategory)));
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
      await ref
          .read(safetyRepositoryProvider)
          .reportIncident(
            tripId: widget.tripId,
            type: type,
            description: description,
            attachmentPaths: _photoStubPath == null
                ? const []
                : [_photoStubPath!],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reportIncidentSubmitted)));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  IconData _iconFor(String iconName) => switch (iconName) {
    'shield' => AlongIcons.shield,
    'payments' => AlongIcons.wallet,
    'directions_car' => AlongIcons.taxi,
    'person' => AlongIcons.user,
    'inventory_2' => AlongIcons.luggage,
    _ => AlongIcons.dots,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);

    return TripPage(
      title: l10n.reportIncidentTitle,
      subtitle: l10n.reportIncidentSubtitle,
      footer: AlongButton(
        key: const Key('report_incident_submit'),
        label: l10n.reportIncidentSubmit,
        visualState: _submitting
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _submitting ? null : _submit,
      ),
      children: [
        Text(l10n.reportIncidentCategoryHeading, style: AlongType.label(p)),
        const SizedBox(height: AlongSpace.s8),
        LayoutBuilder(
          builder: (context, box) {
            const gap = AlongSpace.s8;
            final w = (box.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final category in incidentCategories)
                  SizedBox(
                    width: w,
                    child: TripChoiceTile(
                      key: Key('incident_category_${category.type}'),
                      label: incidentCategoryLabel(
                        category.type,
                        (key) => _l10nKey(l10n, key),
                      ),
                      icon: _iconFor(category.iconName),
                      selected: _selectedType == category.type,
                      onTap: () =>
                          setState(() => _selectedType = category.type),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AlongSpace.s20),
        Text(l10n.reportIncidentDescriptionHeading, style: AlongType.label(p)),
        const SizedBox(height: AlongSpace.s8),
        TextField(
          key: const Key('report_incident_description'),
          controller: _descriptionController,
          maxLength: 2000,
          maxLines: 5,
          minLines: 4,
          style: AlongType.body(p),
          decoration: tripInputDecoration(
            p,
            hint: l10n.reportIncidentDescriptionHint,
          ).copyWith(counterText: ''),
        ),
        const SizedBox(height: AlongSpace.s8),
        TripActionTile(
          key: const Key('report_incident_attach'),
          icon: _photoStubPath == null ? AlongIcons.camera : AlongIcons.check,
          label: _photoStubPath == null
              ? l10n.reportIncidentAttachPhoto
              : l10n.reportIncidentPhotoAttached,
          onPressed: () =>
              setState(() => _photoStubPath = 'stub/incident-photo.jpg'),
        ),
      ],
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

import 'dart:io';
import 'dart:typed_data';

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/live_trip/presentation/widgets/trip_kit.dart';
import 'package:mobile_rider/features/safety/domain/incident_categories.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

enum IncidentPhotoSource { camera, gallery }

/// Picks one photo and copies it into app support storage, so a queued
/// report can still upload it after the OS clears its picker cache.
typedef IncidentPhotoPicker = Future<String?> Function(
  IncidentPhotoSource source,
  String name,
);

final incidentPhotoPickerProvider = Provider<IncidentPhotoPicker>(
  (ref) => (source, name) async {
    final picked = await ImagePicker().pickImage(
      source: source == IncidentPhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 78,
    );
    if (picked == null) return null;
    final dir = Directory(
      '${(await getApplicationSupportDirectory()).path}/incident_photos',
    );
    await dir.create(recursive: true);
    final kept = await File(picked.path).copy('${dir.path}/$name.jpg');
    return kept.path;
  },
);

class _Photo {
  const _Photo(this.path, this.bytes);

  final String path;
  final Uint8List bytes;
}

/// R-24 Report incident — category grid, description, up to four photos.
/// Sends through [IncidentReporter]: uploads first, queues when offline.
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
  final List<_Photo> _photos = [];
  late final String _clientRef = newIncidentClientRef();
  (int, int)? _progress;
  String? _error;

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

    setState(() {
      _submitting = true;
      _error = null;
      _progress = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final delivery = await ref
          .read(incidentReporterProvider)
          .submit(
            IncidentReportDraft(
              clientRef: _clientRef,
              type: type,
              description: description,
              tripId: widget.tripId,
              photoPaths: [for (final photo in _photos) photo.path],
            ),
            onProgress: (done, total) {
              if (mounted) setState(() => _progress = (done, total));
            },
          );
      if (!mounted) return;
      if (delivery == IncidentDelivery.sent) {
        AlongHaptics.success(context);
      } else {
        AlongHaptics.confirm(context);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            delivery == IncidentDelivery.sent
                ? l10n.reportIncidentSent
                : l10n.reportIncidentQueued,
          ),
        ),
      );
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      AlongHaptics.error(context);
      setState(() => _error = l10n.reportIncidentFailed);
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _progress = null;
        });
      }
    }
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<IncidentPhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TripActionTile(
                key: const Key('incident_photo_camera'),
                icon: AlongIcons.camera,
                label: l10n.reportIncidentTakePhoto,
                onPressed: () =>
                    Navigator.of(sheet).pop(IncidentPhotoSource.camera),
              ),
              const SizedBox(height: AlongSpace.s8),
              TripActionTile(
                key: const Key('incident_photo_gallery'),
                icon: AlongIcons.plus,
                label: l10n.reportIncidentChoosePhoto,
                onPressed: () =>
                    Navigator.of(sheet).pop(IncidentPhotoSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final path = await ref.read(incidentPhotoPickerProvider)(
        source,
        '$_clientRef-${DateTime.now().microsecondsSinceEpoch}',
      );
      if (path == null) return;
      final bytes = await ref.read(incidentPhotoBytesProvider)(path);
      if (!mounted) return;
      AlongHaptics.tick(context);
      setState(() => _photos.add(_Photo(path, Uint8List.fromList(bytes))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reportIncidentPhotoError)));
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
        label: switch (_progress) {
          (final done, final total) when done < total =>
            l10n.reportIncidentUploading(done + 1, total),
          _ => l10n.reportIncidentSubmit,
        },
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
        const SizedBox(height: AlongSpace.s12),
        Text(l10n.reportIncidentPhotosHeading, style: AlongType.label(p)),
        const SizedBox(height: AlongSpace.s4),
        Text(l10n.reportIncidentPhotosNote, style: AlongType.bodyMuted(p)),
        const SizedBox(height: AlongSpace.s8),
        Wrap(
          spacing: AlongSpace.s8,
          runSpacing: AlongSpace.s8,
          children: [
            for (final (i, photo) in _photos.indexed)
              _PhotoThumb(
                key: Key('incident_photo_$i'),
                bytes: photo.bytes,
                removeLabel: l10n.reportIncidentRemovePhoto(i + 1),
                onRemove: _submitting
                    ? null
                    : () => setState(() => _photos.removeAt(i)),
              ),
            if (_photos.length < incidentPhotoLimit)
              _AddPhotoTile(
                key: const Key('report_incident_attach'),
                label: l10n.reportIncidentAddPhoto,
                onTap: _submitting ? null : _addPhoto,
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AlongSpace.s12),
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              key: const Key('report_incident_error'),
              style: AlongType.body(p).copyWith(color: p.danger),
            ),
          ),
        ],
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

const double _thumb = 76;

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    super.key,
    required this.bytes,
    required this.removeLabel,
    required this.onRemove,
  });

  final Uint8List bytes;
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    return SizedBox(
      width: _thumb,
      height: _thumb,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AlongRadius.sm.x),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: 228,
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: Semantics(
              button: true,
              label: removeLabel,
              child: InkResponse(
                onTap: onRemove,
                radius: 22,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.surface, width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AlongIcon(
                          AlongIcons.close,
                          size: 12,
                          color: p.onInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AlongPalette.of(context);
    final radius = BorderRadius.circular(AlongRadius.sm.x);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.ink.withValues(alpha: 0.28), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: _thumb,
            height: _thumb,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AlongIcon(AlongIcons.camera, size: 20, color: p.ink),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AlongType.caption(p).copyWith(
                      color: p.ink,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:mobile_rider/features/trip_options/domain/load_capacity_warning.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// R-09 Load flag sheet — size chips, optional note, remember-for-day.
class LoadFlagSheet extends StatefulWidget {
  const LoadFlagSheet({
    super.key,
    required this.initial,
    required this.warnCapacities,
    required this.modeLoadCapacity,
    required this.onApply,
    this.onRequestAnyway,
  });

  final LoadFlagState initial;
  final Map<String, List<String>> warnCapacities;
  final String? modeLoadCapacity;
  final ValueChanged<LoadFlagState> onApply;
  final VoidCallback? onRequestAnyway;

  @override
  State<LoadFlagSheet> createState() => _LoadFlagSheetState();
}

class _LoadFlagSheetState extends State<LoadFlagSheet> {
  late LoadFlagState _load;
  late final TextEditingController _noteController;

  static const _sizes = ['small', 'medium', 'large'];

  @override
  void initState() {
    super.initState();
    _load = widget.initial.flagged
        ? widget.initial
        : widget.initial.copyWith(flagged: true);
    _noteController = TextEditingController(text: _load.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showCapacityWarning = shouldWarnLoadCapacity(
      loadSize: _load.size,
      modeLoadCapacity: widget.modeLoadCapacity,
      warnCapacities: widget.warnCapacities,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AlongSpace.s16,
        right: AlongSpace.s16,
        top: AlongSpace.s16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AlongSpace.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.loadFlagTitle, style: AlongText.heading2),
          const SizedBox(height: AlongSpace.s16),
          Wrap(
            spacing: AlongSpace.s8,
            children: _sizes.map((size) {
              final selected = _load.size == size;
              return ChoiceChip(
                key: Key('load_size_$size'),
                label: Text(_sizeLabel(l10n, size)),
                selected: selected,
                onSelected: (_) {
                  setState(() => _load = _load.copyWith(size: size));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AlongSpace.s16),
          TextField(
            key: const Key('load_flag_note'),
            controller: _noteController,
            maxLength: 140,
            decoration: InputDecoration(
              hintText: l10n.loadFlagNoteHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              _load = _load.copyWith(
                note: value.trim().isEmpty ? null : value.trim(),
              );
            },
          ),
          SwitchListTile(
            key: const Key('load_flag_remember'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.loadFlagRememberDay),
            value: _load.rememberForDay,
            onChanged: (value) {
              setState(() => _load = _load.copyWith(rememberForDay: value));
            },
          ),
          if (showCapacityWarning) ...[
            const SizedBox(height: AlongSpace.s8),
            Container(
              padding: const EdgeInsets.all(AlongSpace.s12),
              decoration: BoxDecoration(
                color: AlongColors.semanticWarningTint,
                borderRadius: BorderRadius.circular(AlongRadius.sm.x),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AlongColors.semanticWarning,
                    size: 20,
                  ),
                  const SizedBox(width: AlongSpace.s8),
                  Expanded(
                    child: Text(
                      l10n.loadFlagCapacityWarning,
                      style: AlongText.caption.copyWith(
                        color: AlongColors.semanticWarning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AlongSpace.s12),
            AlongButton(
              key: const Key('load_flag_request_anyway'),
              label: l10n.loadFlagRequestAnyway,
              variant: AlongButtonVariant.yellow,
              onPressed: () {
                widget.onApply(
                  _load.copyWith(acknowledgedWarning: true),
                );
                widget.onRequestAnyway?.call();
                Navigator.of(context).pop();
              },
            ),
          ] else ...[
            const SizedBox(height: AlongSpace.s8),
            AlongButton(
              key: const Key('load_flag_done'),
              label: l10n.loadFlagDone,
              onPressed: () {
                widget.onApply(_load);
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }

  String _sizeLabel(AppLocalizations l10n, String size) => switch (size) {
        'small' => l10n.loadFlagSizeSmall,
        'medium' => l10n.loadFlagSizeMedium,
        'large' => l10n.loadFlagSizeLarge,
        _ => size,
      };
}

void showLoadFlagSheet(
  BuildContext context, {
  required LoadFlagState initial,
  required Map<String, List<String>> warnCapacities,
  required String? modeLoadCapacity,
  required ValueChanged<LoadFlagState> onApply,
  VoidCallback? onRequestAnyway,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => LoadFlagSheet(
      initial: initial,
      warnCapacities: warnCapacities,
      modeLoadCapacity: modeLoadCapacity,
      onApply: onApply,
      onRequestAnyway: onRequestAnyway,
    ),
  );
}

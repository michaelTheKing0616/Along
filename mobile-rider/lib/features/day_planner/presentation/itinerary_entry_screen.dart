import 'package:along_core/along_core.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/day_planner/presentation/itinerary_entry_controller.dart';
import 'package:mobile_rider/features/trip_options/domain/trip_plan_session.dart';
import 'package:mobile_rider/features/trip_options/presentation/load_flag_sheet.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';
import 'package:mobile_rider/routing/routes.dart';

/// R-21 Itinerary entry — structured rows + NL/voice confirm (doc 06, §5.3).
class ItineraryEntryScreen extends ConsumerStatefulWidget {
  const ItineraryEntryScreen({super.key, this.existingItineraryId});

  final String? existingItineraryId;

  @override
  ConsumerState<ItineraryEntryScreen> createState() =>
      _ItineraryEntryScreenState();
}

class _ItineraryEntryScreenState extends ConsumerState<ItineraryEntryScreen> {
  final _nlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existingId = widget.existingItineraryId;
    if (existingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(itineraryEntryControllerProvider.notifier)
            .configureForExistingItinerary(existingId);
      });
    }
  }

  @override
  void dispose() {
    _nlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(itineraryEntryControllerProvider);
    final controller = ref.read(itineraryEntryControllerProvider.notifier);
    final cityId = ref.watch(alongSupabaseProvider).currentUser != null
        ? 'b1000000-0000-4000-8000-000000000001'
        : 'b1000000-0000-4000-8000-000000000001';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isAddToExisting
              ? l10n.dayPlannerAddStop
              : l10n.itineraryEntryTitle,
        ),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!state.isAddToExisting)
            SwitchListTile(
              key: const Key('itinerary_entry_load_toggle'),
              title: Text(l10n.dayPlannerLoadToggle),
              value: state.load.flagged,
              onChanged: (value) {
                if (value) {
                  showLoadFlagSheet(
                    context,
                    initial: state.load.copyWith(
                      flagged: true,
                      rememberForDay: true,
                    ),
                    warnCapacities: const {},
                    modeLoadCapacity: null,
                    onApply: controller.updateLoad,
                  );
                } else {
                  controller.updateLoad(const LoadFlagState());
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: SegmentedButton<ItineraryEntryMode>(
              key: const Key('itinerary_entry_mode_switch'),
              segments: [
                ButtonSegment(
                  value: ItineraryEntryMode.structured,
                  label: Text(l10n.itineraryEntryStructured),
                ),
                ButtonSegment(
                  value: ItineraryEntryMode.naturalLanguage,
                  label: Text(l10n.itineraryEntryNaturalLanguage),
                ),
              ],
              selected: {state.mode},
              onSelectionChanged: (selection) {
                controller.setMode(selection.first);
              },
            ),
          ),
          Expanded(
            child: state.mode == ItineraryEntryMode.structured
                ? _StructuredEntry(
                    stops: state.stops,
                    onReorder: controller.reorderStructuredStop,
                    onRemove: controller.removeStructuredStop,
                    onLabelChanged: controller.updateStopLabel,
                    onAdd: controller.addStructuredStop,
                  )
                : _NaturalLanguageEntry(
                    controller: _nlController,
                    state: state,
                    onTextChanged: controller.setNlText,
                    onMicTap: () => _showMicStub(context, controller, cityId),
                    onParse: () => controller.parseNaturalLanguage(cityId: cityId),
                  ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s16),
              child: Text(
                state.errorMessage!,
                style: AlongText.caption.copyWith(
                  color: AlongColors.semanticDanger,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AlongSpace.s16),
            child: _BottomActions(
              state: state,
              onLooksRight: () async {
                final view = await controller.confirmAndCreate(cityId: cityId);
                if (view == null || !context.mounted) return;
                if (widget.existingItineraryId != null) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dayPlanner, extra: view.itineraryId);
                }
              },
              onSaveStructured: () async {
                final view = await controller.confirmAndCreate(cityId: cityId);
                if (view == null || !context.mounted) return;
                if (widget.existingItineraryId != null) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dayPlanner, extra: view.itineraryId);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMicStub(
    BuildContext context,
    ItineraryEntryController controller,
    String cityId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final micController = TextEditingController();
    final spoken = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itineraryEntryMicTitle),
        content: TextField(
          controller: micController,
          decoration: InputDecoration(hintText: l10n.itineraryEntryMicHint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.skip),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, micController.text),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
    micController.dispose();
    if (spoken == null || spoken.trim().isEmpty) return;
    _nlController.text = spoken.trim();
    controller.setNlText(spoken.trim());
    await controller.parseNaturalLanguage(cityId: cityId);
  }
}

class _StructuredEntry extends StatelessWidget {
  const _StructuredEntry({
    required this.stops,
    required this.onReorder,
    required this.onRemove,
    required this.onLabelChanged,
    required this.onAdd,
  });

  final List<StructuredStopDraft> stops;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onRemove;
  final void Function(int index, String label) onLabelChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AlongSpace.s16),
            itemCount: stops.length,
            onReorder: onReorder,
            itemBuilder: (context, index) {
              final stop = stops[index];
              return Row(
                key: ValueKey(stop.id),
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle_rounded),
                  ),
                  Expanded(
                    child: SearchField(
                      variant: SearchFieldVariant.full,
                      hint: l10n.itineraryEntryStopHint,
                      controller: TextEditingController(text: stop.label)
                        ..selection = TextSelection.collapsed(
                          offset: stop.label.length,
                        ),
                      onChanged: (value) => onLabelChanged(index, value),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemove(index),
                  ),
                ],
              );
            },
          ),
        ),
        TextButton(onPressed: onAdd, child: Text(l10n.itineraryEntryAddRow)),
      ],
    );
  }
}

class _NaturalLanguageEntry extends StatelessWidget {
  const _NaturalLanguageEntry({
    required this.controller,
    required this.state,
    required this.onTextChanged,
    required this.onMicTap,
    required this.onParse,
  });

  final TextEditingController controller;
  final ItineraryEntryState state;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onMicTap;
  final VoidCallback onParse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AlongSpace.s16),
      children: [
        Text(l10n.itineraryEntryDescribeDay, style: AlongText.bodyStrong),
        const SizedBox(height: AlongSpace.s12),
        TextField(
          key: const Key('itinerary_entry_nl_text'),
          controller: controller,
          onChanged: onTextChanged,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.itineraryEntryNlHint,
            border: AlongCraft.input(const BorderSide()),
          ),
        ),
        const SizedBox(height: AlongSpace.s12),
        Row(
          children: [
            IconButton(
              key: const Key('itinerary_entry_mic'),
              onPressed: onMicTap,
              icon: const Icon(Icons.mic_rounded),
              tooltip: l10n.itineraryEntryMicTitle,
            ),
            const Spacer(),
            AlongButton(
              key: const Key('itinerary_entry_parse'),
              label: l10n.itineraryEntryParse,
              fullWidth: false,
              size: AlongButtonSize.secondary,
              visualState: state.isParsing
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
              onPressed: state.isParsing ? null : onParse,
            ),
          ],
        ),
        if (state.proposal.isNotEmpty) ...[
          const SizedBox(height: AlongSpace.s24),
          Text(l10n.itineraryEntryProposalTitle, style: AlongText.heading2),
          const SizedBox(height: AlongSpace.s8),
          ...state.proposal.map(
            (item) => ListTile(
              key: Key('proposal_${item.sequence}'),
              leading: Icon(
                item.resolved ? Icons.check_circle : Icons.help_outline,
                color: item.resolved
                    ? AlongColors.semanticSuccess
                    : AlongColors.semanticWarning,
              ),
              title: Text(item.destinationDescription),
              subtitle: item.resolved
                  ? Text(item.resolvedLabel ?? '')
                  : Text(l10n.itineraryEntryUnresolved),
            ),
          ),
        ],
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.state,
    required this.onLooksRight,
    required this.onSaveStructured,
  });

  final ItineraryEntryState state;
  final VoidCallback onLooksRight;
  final VoidCallback onSaveStructured;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.mode == ItineraryEntryMode.naturalLanguage &&
        state.proposal.isNotEmpty &&
        state.needsConfirmation) {
      return AlongButton(
        key: const Key('itinerary_entry_looks_right'),
        label: l10n.itineraryEntryLooksRight,
        variant: AlongButtonVariant.yellow,
        visualState: state.isSaving
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: state.isSaving ? null : onLooksRight,
      );
    }

    if (state.mode == ItineraryEntryMode.structured) {
      return AlongButton(
        key: const Key('itinerary_entry_save_structured'),
        label: state.isAddToExisting
            ? l10n.dayPlannerAddStop
            : l10n.itineraryEntrySavePlan,
        visualState: state.isSaving
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: state.isSaving ? null : onSaveStructured,
      );
    }

    return const SizedBox.shrink();
  }
}

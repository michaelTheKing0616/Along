import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/features/day/presentation/seat_layout_editor.dart';
import 'package:mobile_driver/features/vehicle/presentation/vehicle_controller.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// D-05 Vehicle registration (doc 06 D-05).
class VehicleScreen extends ConsumerWidget {
  const VehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(vehicleControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehicleTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      bottomNavigationBar: asyncState.maybeWhen(
        data: (state) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AlongSpace.s24,
              AlongSpace.s8,
              AlongSpace.s24,
              AlongSpace.s16,
            ),
            child: AlongButton(
              key: const Key('vehicle_continue_button'),
              label: l10n.continueButton,
              onPressed: state.isSubmitting
                  ? null
                  : () async {
                      final ok = await ref
                          .read(vehicleControllerProvider.notifier)
                          .submit();
                      if (ok && context.mounted) {
                        context.go(AppRoutes.documents);
                      }
                    },
              visualState: state.isSubmitting
                  ? AlongButtonVisualState.loading
                  : AlongButtonVisualState.normal,
            ),
          ),
        ),
        orElse: () => null,
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.errorGeneric)),
        data: (state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AlongSpace.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.vehicleSubtitle, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: AlongSpace.s16),
                  Wrap(
                    spacing: AlongSpace.s8,
                    runSpacing: AlongSpace.s8,
                    children: [
                      for (final mode in state.modes)
                        FilterChip(
                          key: Key('mode_chip_${mode.code}'),
                          label: Text(mode.label),
                          selected: state.selectedModeCode == mode.code,
                          onSelected: (_) => ref
                              .read(vehicleControllerProvider.notifier)
                              .setMode(mode.code),
                        ),
                    ],
                  ),
                  const SizedBox(height: AlongSpace.s24),
                  Text(l10n.plateLabel, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AlongSpace.s8),
                  TextField(
                    key: const Key('vehicle_plate_field'),
                    decoration: InputDecoration(hintText: l10n.plateHint),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: ref
                        .read(vehicleControllerProvider.notifier)
                        .setPlate,
                  ),
                  const SizedBox(height: AlongSpace.s16),
                  Text(l10n.seatsLabel, style: theme.textTheme.labelLarge),
                  const SizedBox(height: AlongSpace.s8),
                  SeatLayoutEditor(
                    layout: state.layout,
                    reviewSeatMax:
                        state.modes
                            .where(
                              (mode) => mode.code == state.selectedModeCode,
                            )
                            .map((mode) => mode.reviewSeatLimit)
                            .firstOrNull ??
                        state.seatCapacity,
                    onChanged: ref
                        .read(vehicleControllerProvider.notifier)
                        .setLayout,
                    addRowLabel: l10n.addRow,
                    addSeatLabel: l10n.addSeat,
                    removeRowLabel: l10n.removeRow,
                    overCapacityLabel: l10n.overCapacityNote,
                    luggageLabel: l10n.seatLuggage,
                  ),
                  const SizedBox(height: AlongSpace.s16),
                  TextField(
                    decoration: InputDecoration(labelText: l10n.colorLabel),
                    onChanged: ref
                        .read(vehicleControllerProvider.notifier)
                        .setColor,
                  ),
                  const SizedBox(height: AlongSpace.s16),
                  TextField(
                    decoration: InputDecoration(labelText: l10n.makeModelLabel),
                    onChanged: ref
                        .read(vehicleControllerProvider.notifier)
                        .setMakeModel,
                  ),
                  const SizedBox(height: AlongSpace.s24),
                  Text(l10n.ownerQuestion, style: theme.textTheme.labelLarge),
                  RadioGroup<bool>(
                    groupValue: state.ownerIsMe,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(vehicleControllerProvider.notifier)
                            .setOwnerIsMe(value);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          title: Text(l10n.ownerYes),
                          value: true,
                        ),
                        RadioListTile<bool>(
                          title: Text(l10n.ownerNo),
                          value: false,
                        ),
                      ],
                    ),
                  ),
                  if (!state.ownerIsMe) ...[
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.ownerNameLabel,
                      ),
                      onChanged: ref
                          .read(vehicleControllerProvider.notifier)
                          .setOwnerName,
                    ),
                    const SizedBox(height: AlongSpace.s8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: l10n.ownerPhoneLabel,
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: ref
                          .read(vehicleControllerProvider.notifier)
                          .setOwnerPhone,
                    ),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: AlongSpace.s16),
                    Text(
                      state.errorMessage == 'conflict'
                          ? l10n.errorPlateConflict
                          : l10n.errorValidation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AlongColors.semanticDangerFill,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// The driver's own target, the corridor they are watching, and a fuel note.
class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _goal = TextEditingController();
  final _earned = TextEditingController();
  final _typical = TextEditingController();
  final _corridor = TextEditingController();
  final _requests = TextEditingController();
  final _fuelLabel = TextEditingController();
  final _fuelPrice = TextEditingController();
  final _eventName = TextEditingController();
  final _eventHours = TextEditingController();
  var _demand = const <CorridorDemand>[];

  @override
  void dispose() {
    _goal.dispose();
    _earned.dispose();
    _typical.dispose();
    _corridor.dispose();
    _requests.dispose();
    _fuelLabel.dispose();
    _fuelPrice.dispose();
    _eventName.dispose();
    _eventHours.dispose();
    super.dispose();
  }

  GoalProgress? get _progress {
    return dailyGoal(
      targetMinor: _naira(_goal.text),
      earnedMinor: _naira(_earned.text) ?? 0,
      typicalFareMinor: _naira(_typical.text),
    );
  }

  int? _naira(String raw) {
    final major = int.tryParse(raw.trim());
    if (major == null) return null;
    return major * 100;
  }

  Future<void> _saveGoal() async {
    final target = _naira(_goal.text);
    try {
      await ref
          .read(alongSupabaseProvider)
          .rpc('save_earnings_goal', params: {'p_target_minor': target});
    } catch (_) {}
  }

  void _addCorridor() {
    final count = int.tryParse(_requests.text.trim());
    if (count == null) return;
    setState(() {
      _demand = [
        ..._demand,
        CorridorDemand(label: _corridor.text.trim(), requests: count),
      ];
      _corridor.clear();
      _requests.clear();
    });
  }

  Future<void> _saveFuel() async {
    final price = double.tryParse(_fuelPrice.text.trim());
    if (price == null) return;
    try {
      await ref
          .read(alongSupabaseProvider)
          .rpc(
            'record_fuel_note',
            params: {
              'p_label': _fuelLabel.text.trim(),
              'p_price_naira': price,
              'p_lat': 0,
              'p_lng': 0,
              'p_client_ref': 'fuel-${DateTime.now().millisecondsSinceEpoch}',
            },
          );
    } catch (_) {}
  }

  Future<void> _openEvent() async {
    final hours = int.tryParse(_eventHours.text.trim());
    final name = _eventName.text.trim();
    if (hours == null || hours < 1 || name.isEmpty) return;
    final start = DateTime.now().toUtc();
    try {
      await ref
          .read(alongSupabaseProvider)
          .rpc(
            'open_pickup_event',
            params: {
              'p_name': name,
              'p_starts': start.toIso8601String(),
              'p_ends': start.add(Duration(hours: hours)).toIso8601String(),
              'p_lat': 0,
              'p_lng': 0,
              'p_client_ref': 'event-${start.millisecondsSinceEpoch}',
            },
          );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = _progress;
    final tip = corridorTip(_demand);
    return DrivePage(
      title: l10n.marketplaceTitle,
      children: [
        DriveSection(l10n.mpGoalSection),
        TextField(
          key: const Key('marketplace_goal'),
          controller: _goal,
          keyboardType: TextInputType.number,
          decoration: driveInput(context, l10n.marketplaceGoal),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AlongSpace.s12),
        TextField(
          key: const Key('marketplace_earned'),
          controller: _earned,
          keyboardType: TextInputType.number,
          decoration: driveInput(context, l10n.marketplaceEarned),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AlongSpace.s12),
        TextField(
          key: const Key('marketplace_typical'),
          controller: _typical,
          keyboardType: TextInputType.number,
          decoration: driveInput(context, l10n.marketplaceTypical),
          onChanged: (_) => setState(() {}),
        ),
        if (progress != null)
          Text(
            progress.seatsLeft == 0
                ? l10n.marketplaceGoalMet
                : l10n.marketplaceSeats(progress.seatsLeft),
            key: const Key('marketplace_seats'),
            style: AlongType.label(AlongPalette.of(context)),
          ),
        const SizedBox(height: AlongSpace.s8),
        AlongButton(
          key: const Key('marketplace_goal_save'),
          label: l10n.marketplaceSave,
          onPressed: _saveGoal,
        ),
        DriveSection(l10n.mpDemandSection),
        TextField(
          key: const Key('marketplace_corridor'),
          controller: _corridor,
          decoration: driveInput(context, l10n.marketplaceCorridor),
        ),
        const SizedBox(height: AlongSpace.s12),
        TextField(
          key: const Key('marketplace_requests'),
          controller: _requests,
          keyboardType: TextInputType.number,
          decoration: driveInput(context, l10n.marketplaceRequests),
        ),
        const SizedBox(height: AlongSpace.s12),
        AlongButton(
          key: const Key('marketplace_add_corridor'),
          label: l10n.marketplaceAddCorridor,
          variant: AlongButtonVariant.secondary,
          onPressed: _addCorridor,
        ),
        if (tip != null)
          Text(
            l10n.marketplaceTip(tip),
            key: const Key('marketplace_tip'),
            style: AlongType.body(AlongPalette.of(context)),
          ),
        DriveSection(l10n.mpFuelSection),
        TextField(
          key: const Key('marketplace_fuel_label'),
          controller: _fuelLabel,
          decoration: driveInput(context, l10n.marketplaceFuelLabel),
        ),
        const SizedBox(height: AlongSpace.s12),
        TextField(
          key: const Key('marketplace_fuel_price'),
          controller: _fuelPrice,
          keyboardType: TextInputType.number,
          decoration: driveInput(context, l10n.marketplaceFuel),
        ),
        const SizedBox(height: AlongSpace.s12),
        AlongButton(
          key: const Key('marketplace_fuel_save'),
          label: l10n.marketplaceFuelSave,
          variant: AlongButtonVariant.secondary,
          onPressed: _saveFuel,
        ),
        DriveSection(l10n.mpEventSection),
        TextField(
          key: const Key('marketplace_event'),
          controller: _eventName,
          decoration: driveInput(context, l10n.marketplaceEventName),
        ),
        const SizedBox(height: AlongSpace.s12),
        TextField(
          key: const Key('marketplace_event_hours'),
          controller: _eventHours,
          keyboardType: TextInputType.number,
          decoration: driveInput(context, l10n.marketplaceEventHours),
        ),
        const SizedBox(height: AlongSpace.s12),
        AlongButton(
          key: const Key('marketplace_event_save'),
          label: l10n.marketplaceEventSave,
          variant: AlongButtonVariant.secondary,
          onPressed: _openEvent,
        ),
      ],
    );
  }
}

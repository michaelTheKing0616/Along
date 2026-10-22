import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/day/presentation/seat_layout_editor.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';

/// Pick a vehicle, corridor, a named seat layout, and the rules riders will see.
class BuildMyDayScreen extends ConsumerStatefulWidget {
  const BuildMyDayScreen({super.key});

  @override
  ConsumerState<BuildMyDayScreen> createState() => _BuildMyDayScreenState();
}

class _BuildMyDayScreenState extends ConsumerState<BuildMyDayScreen> {
  DaySetup? _setup;
  String? _vehicleId;
  String? _corridorId;
  String? _routeId;
  String? _layoutId;
  SeatLayout? _layout;
  final _nameController = TextEditingController(text: 'Day');
  var _loading = true;
  var _saving = false;
  String? _error;
  String? _targetRow;
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _customTitle = TextEditingController();
  final _customBody = TextEditingController();
  final _minutes = TextEditingController(text: '3');
  final _walk = TextEditingController(text: '0');
  final _max = TextEditingController(text: '1');
  final _shiftStart = TextEditingController();
  final _shiftEnd = TextEditingController();
  final _home = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _title.dispose();
    _body.dispose();
    _customTitle.dispose();
    _customBody.dispose();
    _minutes.dispose();
    _walk.dispose();
    _max.dispose();
    _shiftStart.dispose();
    _shiftEnd.dispose();
    _home.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final setup = await ref.read(seatRepositoryProvider).myDaySetup();
      if (!mounted) return;
      final vehicle = setup.vehicles.isEmpty ? null : setup.vehicles.first;
      setState(() {
        _setup = setup;
        _vehicleId = vehicle?.id;
        _corridorId = setup.corridors.isEmpty ? null : setup.corridors.first.id;
        _applyVehicle(setup, vehicle);
        _loading = false;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is AlongException ? error.message : 'error';
      });
    }
  }

  void _applyVehicle(DaySetup setup, DayVehicle? vehicle) {
    final saved = setup.layouts
        .where((layout) => layout.vehicleId == vehicle?.id)
        .toList();
    if (saved.isNotEmpty) {
      SavedLayout active = saved.first;
      for (final layout in saved) {
        if (layout.isActive) active = layout;
      }
      _layoutId = active.id;
      _layout = active.layout;
      _nameController.text = active.name;
    } else if (vehicle?.layoutPreset != null) {
      _layoutId = null;
      _layout = SeatLayout.fromJson(vehicle!.layoutPreset!);
      _nameController.text = 'Day';
    } else {
      _layoutId = null;
      _layout = SeatLayout.starter(passengerSeats: vehicle?.seatCapacity ?? 4);
      _nameController.text = 'Day';
    }
    _targetRow = _layout?.rows.isNotEmpty == true
        ? _layout!.rows.first.id
        : null;
  }

  DayVehicle? get _vehicle {
    final setup = _setup;
    if (setup == null || _vehicleId == null) return null;
    for (final vehicle in setup.vehicles) {
      if (vehicle.id == _vehicleId) return vehicle;
    }
    return null;
  }

  Future<void> _saveLayout() async {
    final layout = _layout;
    final vehicleId = _vehicleId;
    if (layout == null ||
        vehicleId == null ||
        _nameController.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(seatRepositoryProvider)
          .saveVehicleLayout(
            vehicleId: vehicleId,
            name: _nameController.text.trim(),
            layout: layout,
          );
      if (!mounted) return;
      setState(() {
        _layoutId = saved['id'] as String?;
        _saving = false;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is AlongException ? error.message : 'error';
      });
    }
  }

  Future<void> _addPreset(RideRulePreset preset) async {
    final vehicleId = _vehicleId;
    if (vehicleId == null) return;
    final params = Map<String, dynamic>.from(preset.defaultParams);
    if (preset.effect == 'hold_minutes') {
      params['duration_minutes'] = int.tryParse(_minutes.text) ?? 3;
      params['walk_extension_minutes'] = int.tryParse(_walk.text) ?? 0;
    }
    if (preset.effect == 'cap_seats') {
      params['max'] = int.tryParse(_max.text) ?? 1;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(seatRepositoryProvider)
          .saveRideRule(
            vehicleId: vehicleId,
            presetId: preset.id,
            title: _title.text.trim().isEmpty
                ? preset.title
                : _title.text.trim(),
            body: _body.text.trim().isEmpty ? preset.body : _body.text.trim(),
            params: params,
            targetRef: preset.targetScope == 'vehicle' ? null : _targetRow,
          );
      _title.clear();
      _body.clear();
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is AlongException ? error.message : 'error';
      });
    }
  }

  Future<void> _addCustom() async {
    final vehicleId = _vehicleId;
    if (vehicleId == null || _customTitle.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(seatRepositoryProvider)
          .saveRideRule(
            vehicleId: vehicleId,
            title: _customTitle.text.trim(),
            body: _customBody.text.trim(),
          );
      _customTitle.clear();
      _customBody.clear();
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is AlongException ? error.message : 'error';
      });
    }
  }

  Future<void> _deleteRule(String id) async {
    await ref.read(seatRepositoryProvider).deleteRideRule(id);
    await _load();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final vehicleId = _vehicleId;
    final corridorId = _corridorId;
    if (vehicleId == null || corridorId == null) {
      setState(() => _error = l10n.dayNeedsCorridor);
      return;
    }
    setState(() => _saving = true);
    try {
      var layoutId = _layoutId;
      if (layoutId == null && _layout != null) {
        final saved = await ref
            .read(seatRepositoryProvider)
            .saveVehicleLayout(
              vehicleId: vehicleId,
              name: _nameController.text.trim().isEmpty
                  ? 'Day'
                  : _nameController.text.trim(),
              layout: _layout!,
            );
        layoutId = saved['id'] as String?;
      }
      if (layoutId == null) {
        setState(() => _saving = false);
        return;
      }
      await ref
          .read(seatRepositoryProvider)
          .startDriverDay(
            vehicleId: vehicleId,
            layoutId: layoutId,
            corridorId: corridorId,
            routeId: _routeId,
            shiftStart: _clock(_shiftStart.text),
            shiftEnd: _clock(_shiftEnd.text),
            homeLabel: _home.text.trim().isEmpty ? null : _home.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is AlongException ? error.message : 'error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final setup = _setup;
    final layout = _layout;
    final vehicle = _vehicle;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.buildMyDayTitle),
        backgroundColor: AlongColors.surface0,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AlongSpace.s16),
                children: [
                  if (setup != null) ...[
                    Text(l10n.vehicleTitle, style: AlongText.label),
                    Wrap(
                      spacing: AlongSpace.s8,
                      children: [
                        for (final item in setup.vehicles)
                          ChoiceChip(
                            key: Key('day_vehicle_${item.id}'),
                            label: Text(item.plateNumber),
                            selected: item.id == _vehicleId,
                            onSelected: (_) => setState(() {
                              _vehicleId = item.id;
                              _applyVehicle(setup, item);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AlongSpace.s12),
                    Text(l10n.buildMyDayCorridor, style: AlongText.label),
                    Wrap(
                      spacing: AlongSpace.s8,
                      children: [
                        for (final corridor in setup.corridors)
                          ChoiceChip(
                            label: Text(corridor.name),
                            selected: corridor.id == _corridorId,
                            onSelected: (_) => setState(() {
                              _corridorId = corridor.id;
                              _routeId = null;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AlongSpace.s12),
                    Wrap(
                      spacing: AlongSpace.s8,
                      children: [
                        for (final route in setup.routes)
                          if (route.corridorId == _corridorId)
                            ChoiceChip(
                              label: Text(route.name ?? route.modeCode),
                              selected: route.id == _routeId,
                              onSelected: (_) =>
                                  setState(() => _routeId = route.id),
                            ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AlongSpace.s12),
                  TextField(
                    key: const Key('layout_name_field'),
                    decoration: InputDecoration(labelText: l10n.layoutName),
                    controller: _nameController,
                  ),
                  const SizedBox(height: AlongSpace.s12),
                  if (layout != null)
                    SeatLayoutEditor(
                      layout: layout,
                      reviewSeatMax:
                          vehicle?.reviewSeatMax ?? layout.passengerCount,
                      onChanged: (next) => setState(() => _layout = next),
                      addRowLabel: l10n.addRow,
                      addSeatLabel: l10n.addSeat,
                      removeRowLabel: l10n.removeRow,
                      overCapacityLabel: l10n.overCapacityNote,
                      luggageLabel: l10n.seatLuggage,
                    ),
                  const SizedBox(height: AlongSpace.s12),
                  AlongButton(
                    key: const Key('save_layout_button'),
                    label: l10n.saveLayout,
                    variant: AlongButtonVariant.secondary,
                    onPressed: _saving ? null : _saveLayout,
                  ),
                  const SizedBox(height: AlongSpace.s24),
                  Text(l10n.rideRulesHeading, style: AlongText.bodyStrong),
                  if (setup != null)
                    for (final rule in setup.rules.where(
                      (rule) => rule.enabled,
                    ))
                      ListTile(
                        title: Text(rule.title),
                        subtitle: Text(rule.body ?? rule.effect),
                        trailing: IconButton(
                          tooltip: l10n.deleteRule,
                          onPressed: () => _deleteRule(rule.id),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                  if (layout != null)
                    Wrap(
                      spacing: AlongSpace.s8,
                      children: [
                        for (final row in layout.rows)
                          ChoiceChip(
                            label: Text(row.id),
                            selected: _targetRow == row.id,
                            onSelected: (_) =>
                                setState(() => _targetRow = row.id),
                          ),
                      ],
                    ),
                  TextField(
                    key: const Key('day_shift_start'),
                    decoration: InputDecoration(labelText: l10n.shiftStart),
                    controller: _shiftStart,
                  ),
                  TextField(
                    key: const Key('day_shift_end'),
                    decoration: InputDecoration(labelText: l10n.shiftEnd),
                    controller: _shiftEnd,
                  ),
                  TextField(
                    key: const Key('day_home_label'),
                    decoration: InputDecoration(labelText: l10n.homeLabel),
                    controller: _home,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: l10n.holdMinutes),
                    keyboardType: TextInputType.number,
                    controller: _minutes,
                  ),
                  TextField(
                    key: const Key('day_walk_minutes'),
                    decoration: InputDecoration(labelText: l10n.walkExtension),
                    keyboardType: TextInputType.number,
                    controller: _walk,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: l10n.capMax),
                    keyboardType: TextInputType.number,
                    controller: _max,
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: l10n.customRuleHint),
                    controller: _title,
                  ),
                  TextField(
                    controller: _body,
                    decoration: const InputDecoration(labelText: ''),
                  ),
                  if (setup != null)
                    for (final preset in setup.presets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AlongSpace.s8),
                        child: AlongButton(
                          key: Key('add_preset_${preset.id}'),
                          label: preset.title,
                          variant: AlongButtonVariant.secondary,
                          onPressed: _saving ? null : () => _addPreset(preset),
                        ),
                      ),
                  TextField(
                    key: const Key('custom_rule_title'),
                    decoration: InputDecoration(labelText: l10n.customRuleHint),
                    controller: _customTitle,
                  ),
                  TextField(
                    key: const Key('custom_rule_body'),
                    decoration: InputDecoration(labelText: l10n.customRuleBody),
                    controller: _customBody,
                    maxLength: 280,
                  ),
                  AlongButton(
                    key: const Key('save_custom_rule'),
                    label: l10n.customRuleSave,
                    variant: AlongButtonVariant.secondary,
                    onPressed: _saving ? null : _addCustom,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AlongSpace.s12),
                    Text(
                      _error!,
                      style: AlongText.caption.copyWith(
                        color: AlongColors.semanticDanger,
                      ),
                    ),
                  ],
                  const SizedBox(height: AlongSpace.s16),
                  AlongButton(
                    key: const Key('start_day_button'),
                    label: l10n.buildMyDayStart,
                    onPressed: _saving ? null : _start,
                  ),
                ],
              ),
            ),
    );
  }
}

String? _clock(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
  if (match == null) return null;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return null;
  final hh = hour.toString().padLeft(2, '0');
  final mm = minute.toString().padLeft(2, '0');
  return '$hh:$mm:00';
}

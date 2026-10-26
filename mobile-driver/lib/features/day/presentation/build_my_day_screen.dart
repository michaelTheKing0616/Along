import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/features/day/presentation/build_my_day_sections.dart';
import 'package:mobile_driver/features/day/presentation/seat_layout_editor.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/widgets/drive_kit.dart';

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

  /// Which optional rule panel is open: 'details' or 'custom'.
  String? _rulePanel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = AlongPalette.of(context);
    final setup = _setup;
    final layout = _layout;
    final vehicle = _vehicle;
    if (_loading) {
      return DrivePage(
        title: l10n.buildMyDayTitle,
        children: const [
          SizedBox(height: AlongSpace.s16),
          AlongSkeleton(variant: SkeletonVariant.line),
        ],
      );
    }
    final rules = setup?.rules.where((rule) => rule.enabled).toList() ?? [];
    return DrivePage(
      title: l10n.buildMyDayTitle,
      subtitle: l10n.daySubtitle,
      footer: AlongButton(
        key: const Key('start_day_button'),
        label: l10n.buildMyDayStart,
        visualState: _saving
            ? AlongButtonVisualState.loading
            : AlongButtonVisualState.normal,
        onPressed: _saving ? null : _start,
      ),
      children: [
        if (setup != null) ...[
          DriveSection(l10n.vehicleTitle),
          DayVehiclePicker(
            vehicles: setup.vehicles,
            selectedId: _vehicleId,
            seatsLabel: l10n.daySeatsCount,
            onSelect: (item) => setState(() {
              _vehicleId = item.id;
              _applyVehicle(setup, item);
            }),
          ),
          DriveSection(l10n.buildMyDayCorridor),
          DriveChips(
            items: [
              for (final corridor in setup.corridors)
                (
                  Key('day_corridor_${corridor.id}'),
                  corridor.name,
                  corridor.id == _corridorId,
                  () => setState(() {
                    _corridorId = corridor.id;
                    _routeId = null;
                  }),
                ),
            ],
          ),
          if (setup.routes.any((r) => r.corridorId == _corridorId)) ...[
            const SizedBox(height: AlongSpace.s12),
            Text(l10n.dayRouteOptional, style: AlongType.bodyMuted(p)),
            const SizedBox(height: AlongSpace.s8),
            DriveChips(
              items: [
                for (final route in setup.routes)
                  if (route.corridorId == _corridorId)
                    (
                      Key('day_route_${route.id}'),
                      route.name ?? route.modeCode,
                      route.id == _routeId,
                      () => setState(
                        () => _routeId = _routeId == route.id ? null : route.id,
                      ),
                    ),
              ],
            ),
          ],
        ],
        const SizedBox(height: AlongSpace.s24),
        const AlongDepartureBoard(),
        DriveSection(l10n.dayHoursSection),
        DayHoursFields(
          start: _shiftStart,
          end: _shiftEnd,
          home: _home,
          startLabel: l10n.shiftStart,
          endLabel: l10n.shiftEnd,
          homeLabel: l10n.homeLabel,
        ),
        DriveSection(l10n.daySeatsSection),
        TextField(
          key: const Key('layout_name_field'),
          decoration: driveInput(context, l10n.layoutName),
          controller: _nameController,
        ),
        const SizedBox(height: AlongSpace.s12),
        if (layout != null)
          SeatLayoutEditor(
            layout: layout,
            reviewSeatMax: vehicle?.reviewSeatMax ?? layout.passengerCount,
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
        DriveSection(l10n.rideRulesHeading),
        if (rules.isNotEmpty) ...[
          DriveRows(
            children: [
              for (final rule in rules)
                DriveRow(
                  key: Key('day_rule_${rule.id}'),
                  icon: AlongIcons.info,
                  title: rule.title,
                  detail: rule.body ?? rule.effect,
                  trailing: l10n.dayRemove,
                  trailingStyle: AlongType.caption(p).copyWith(color: p.danger),
                  onTap: () => _deleteRule(rule.id),
                ),
            ],
          ),
          const SizedBox(height: AlongSpace.s12),
        ],
        if (setup != null && setup.presets.isNotEmpty) ...[
          Text(l10n.dayAddRule, style: AlongType.bodyMuted(p)),
          const SizedBox(height: AlongSpace.s8),
          DriveChips(
            items: [
              for (final preset in setup.presets)
                (
                  Key('add_preset_${preset.id}'),
                  '+ ${preset.title}',
                  false,
                  _saving ? null : () => _addPreset(preset),
                ),
            ],
          ),
          if (layout != null && layout.rows.length > 1) ...[
            const SizedBox(height: AlongSpace.s12),
            Text(l10n.dayRuleRow, style: AlongType.bodyMuted(p)),
            const SizedBox(height: AlongSpace.s8),
            DriveChips(
              items: [
                for (final (n, row) in layout.rows.indexed)
                  (
                    Key('day_row_${row.id}'),
                    l10n.dayRowN(n + 1),
                    _targetRow == row.id,
                    () => setState(() => _targetRow = row.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AlongSpace.s12),
        ],
        DriveRows(
          children: [
            DriveRow(
              key: const Key('day_rule_details_toggle'),
              icon: AlongIcons.schedule,
              title: l10n.dayRuleDetails,
              detail: l10n.dayRuleDetailsBody,
              chevron: _rulePanel != 'details',
              onTap: () => setState(
                () => _rulePanel = _rulePanel == 'details' ? null : 'details',
              ),
            ),
            DriveRow(
              key: const Key('day_custom_rule_toggle'),
              icon: AlongIcons.plus,
              title: l10n.dayCustomRule,
              detail: l10n.dayCustomRuleBody,
              chevron: _rulePanel != 'custom',
              onTap: () => setState(
                () => _rulePanel = _rulePanel == 'custom' ? null : 'custom',
              ),
            ),
          ],
        ),
        if (_rulePanel == 'details')
          DayRuleDetailsFields(
            minutes: _minutes,
            walk: _walk,
            max: _max,
            title: _title,
            body: _body,
            minutesLabel: l10n.holdMinutes,
            walkLabel: l10n.walkExtension,
            maxLabel: l10n.capMax,
            titleLabel: l10n.customRuleHint,
            bodyLabel: l10n.customRuleBody,
          ),
        if (_rulePanel == 'custom') ...[
          const SizedBox(height: AlongSpace.s12),
          TextField(
            key: const Key('custom_rule_title'),
            decoration: driveInput(context, l10n.customRuleHint),
            controller: _customTitle,
          ),
          const SizedBox(height: AlongSpace.s8),
          TextField(
            key: const Key('custom_rule_body'),
            decoration: driveInput(context, l10n.customRuleBody),
            controller: _customBody,
            maxLength: 280,
          ),
          AlongButton(
            key: const Key('save_custom_rule'),
            label: l10n.customRuleSave,
            variant: AlongButtonVariant.secondary,
            onPressed: _saving ? null : _addCustom,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AlongSpace.s12),
          Text(_error!, style: AlongType.caption(p).copyWith(color: p.danger)),
        ],
      ],
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

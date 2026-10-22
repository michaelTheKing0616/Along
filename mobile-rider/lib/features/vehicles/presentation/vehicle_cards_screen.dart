import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_rider/di/providers.dart';
import 'package:mobile_rider/features/home/presentation/home_controller.dart';
import 'package:mobile_rider/l10n/app_localizations.dart';

/// Vehicles a rider can see before booking, with the driver's own rules.
class VehicleCardsScreen extends ConsumerStatefulWidget {
  const VehicleCardsScreen({super.key});

  @override
  ConsumerState<VehicleCardsScreen> createState() => _VehicleCardsScreenState();
}

class _VehicleCardsScreenState extends ConsumerState<VehicleCardsScreen> {
  VehicleCardFeed? _feed;
  final _selectedPresets = <String>{};
  final _query = TextEditingController();
  var _loading = true;
  String? _notice;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cityId = ref.read(homeControllerProvider).cityId;
    if (cityId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final feed = await ref
          .read(seatRepositoryProvider)
          .onlineVehicleCards(
            cityId: cityId,
            presetIds: _selectedPresets.toList(),
            query: _query.text,
          );
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _claim(VehicleCard card, String seatId) async {
    final l10n = AppLocalizations.of(context);
    final seat = card.layout.seatById(seatId);
    if (seat == null || !seat.isPassenger) return;
    final state = _state(card, seatId);
    final engine = const SeatRuleEngine();
    final rowId = card.layout.rowIdOf(seatId);
    final acks = engine.acknowledgementsRequired(
      rules: card.rules,
      seatId: seatId,
      rowId: rowId,
    );
    final caps = engine.capBlocksClaim(
      rules: card.rules,
      layout: card.layout,
      seatId: seatId,
      states: {
        for (final item in card.seats)
          item.seatId: SeatOccupancy(
            status: item.status,
            holdUntil: item.holdUntil,
            version: item.version,
          ),
      },
    );
    if (caps.isNotEmpty) {
      setState(() => _notice = caps.map((rule) => rule.title).join('\n'));
      return;
    }
    if (acks.isNotEmpty) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(acks.first.title),
          content: Text(acks.map((rule) => rule.body ?? rule.title).join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.meetVehicleCancel),
            ),
            TextButton(
              key: const Key('ack_rule_confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.acknowledgeToClaim),
            ),
          ],
        ),
      );
      if (accepted != true) return;
    }
    try {
      final result = await ref
          .read(seatRepositoryProvider)
          .claimSeat(
            layoutId: card.layoutId,
            seatId: seatId,
            expectedVersion: state?.version ?? 1,
            ackRuleIds: [for (final rule in acks) rule.id],
          );
      if (seatDeltaPayloadBytes(result.toJson()) > 200) {
        setState(() => _notice = l10n.seatTaken);
      }
      await _load();
    } on AlongException catch (error) {
      final title = switch (error.code) {
        AlongErrorCode.ruleCap => caps.map((rule) => rule.title).join('\n'),
        AlongErrorCode.ruleAck => acks.map((rule) => rule.title).join('\n'),
        AlongErrorCode.conflict => l10n.seatTaken,
        _ => error.message,
      };
      if (mounted) setState(() => _notice = title);
    }
  }

  SeatState? _state(VehicleCard card, String seatId) {
    for (final seat in card.seats) {
      if (seat.seatId == seatId) return seat;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final feed = _feed;
    final cards = [
      for (final card in feed?.cards ?? const <VehicleCard>[])
        if (!card.hiddenAt(now) &&
            rulesMatchFilter(
              rules: card.rules,
              presetIds: _selectedPresets.toList(),
              query: _query.text,
            ))
          card,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehiclesTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AlongSpace.s16),
              children: [
                TextField(
                  key: const Key('vehicle_rule_query'),
                  controller: _query,
                  decoration: InputDecoration(hintText: l10n.filterRulesHint),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: AlongSpace.s8),
                Wrap(
                  spacing: AlongSpace.s8,
                  children: [
                    for (final preset
                        in feed?.presets ?? const <RideRulePreset>[])
                      FilterChip(
                        key: Key('rule_filter_${preset.id}'),
                        label: Text(preset.title),
                        selected: _selectedPresets.contains(preset.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedPresets.add(preset.id);
                            } else {
                              _selectedPresets.remove(preset.id);
                            }
                          });
                          _load();
                        },
                      ),
                  ],
                ),
                if (cards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AlongSpace.s24),
                    child: Text(l10n.noVehicles),
                  ),
                for (final card in cards) ...[
                  const SizedBox(height: AlongSpace.s16),
                  Text(
                    '${card.plateNumber} · ${l10n.freeSeatCount(card.freeCount)}',
                    style: AlongText.bodyStrong,
                  ),
                  if (card.staleAt(now))
                    Text(
                      l10n.seatStale,
                      style: AlongText.caption.copyWith(
                        color: AlongColors.semanticWarning,
                      ),
                    ),
                  for (final rule in card.rules)
                    Text(
                      rule.body == null
                          ? rule.title
                          : '${rule.title}. ${rule.body}',
                    ),
                  const SizedBox(height: AlongSpace.s8),
                  for (final rule in card.rules)
                    if (rule.effect == 'bundle')
                      Padding(
                        padding: const EdgeInsets.only(bottom: AlongSpace.s8),
                        child: AlongButton(
                          key: Key('book_bundle_${rule.id}'),
                          label: rule.title,
                          onPressed: () => _claimBundle(card, rule),
                        ),
                      ),
                  SeatMap(
                    body: card.layout.body,
                    rows: [
                      for (final row in card.layout.rows)
                        SeatMapRowView(
                          id: row.id,
                          ruleTitle: _rowRule(card.rules, row.id),
                          seats: [
                            for (final seat in row.seats)
                              SeatMapSeat(
                                id: seat.id,
                                label: seat.label,
                                role: seat.role,
                                status: _state(card, seat.id)?.status ?? 'free',
                                statusWord: seat.isCargo
                                    ? l10n.seatLuggage
                                    : seat.isPassenger
                                    ? _word(
                                        l10n,
                                        _state(card, seat.id)?.status ?? 'free',
                                      )
                                    : l10n.seatDriver,
                              ),
                          ],
                        ),
                    ],
                    onSeatTap: (seatId) => _claim(card, seatId),
                    onSeatLongPress: (seatId) => _hold(card, seatId),
                  ),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: AlongSpace.s12),
                  Text(
                    _notice!,
                    key: const Key('vehicle_rule_notice'),
                    style: AlongText.bodyStrong,
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _claimBundle(VehicleCard card, RideRule rule) async {
    try {
      await ref
          .read(seatRepositoryProvider)
          .claimBundle(layoutId: card.layoutId, ruleId: rule.id);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error is AlongException ? error.message : rule.title;
      });
    }
  }

  Future<void> _hold(VehicleCard card, String seatId) async {
    final l10n = AppLocalizations.of(context);
    final engine = const SeatRuleEngine();
    final rowId = card.layout.rowIdOf(seatId);
    final minutes = engine.holdMinutes(
      rules: card.rules,
      seatId: seatId,
      rowId: rowId,
    );
    if (minutes == null) {
      setState(() => _notice = l10n.holdNotOffered);
      return;
    }
    final cap = engine.walkExtensionMinutes(
      rules: card.rules,
      seatId: seatId,
      rowId: rowId,
    );
    var walk = 0;
    if (cap > 0) {
      final controller = TextEditingController();
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.walkExtension),
          content: TextField(
            key: const Key('walk_minutes_field'),
            controller: controller,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.acknowledgeToClaim),
            ),
          ],
        ),
      );
      walk = int.tryParse(controller.text) ?? 0;
      controller.dispose();
      if (accepted != true) return;
    }
    final state = _state(card, seatId);
    try {
      await ref
          .read(seatRepositoryProvider)
          .holdSeat(
            layoutId: card.layoutId,
            seatId: seatId,
            expectedVersion: state?.version ?? 1,
            walkMinutes: walk,
          );
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notice = error is AlongException ? error.message : l10n.seatTaken;
      });
    }
  }

  String _word(AppLocalizations l10n, String status) {
    return switch (status) {
      'occupied' => l10n.seatOccupied,
      'held' => l10n.seatHeld,
      'blocked' => l10n.seatBlocked,
      _ => l10n.seatFree,
    };
  }

  String? _rowRule(List<RideRule> rules, String rowId) {
    final titles = [
      for (final rule in rules)
        if (rule.targetScope == 'row' && rule.targetRef == rowId) rule.title,
    ];
    if (titles.isEmpty) return null;
    return titles.join(' · ');
  }
}

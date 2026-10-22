import 'package:along_core/along_core.dart';
import 'package:along_data/along_data.dart';
import 'package:along_design/along_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_driver/di/providers.dart';
import 'package:mobile_driver/l10n/app_localizations.dart';
import 'package:mobile_driver/routing/routes.dart';

/// One-tap occupied / free diagram for the driver's active layout.
class SeatBoardScreen extends ConsumerStatefulWidget {
  const SeatBoardScreen({super.key});

  @override
  ConsumerState<SeatBoardScreen> createState() => _SeatBoardScreenState();
}

class _SeatBoardScreenState extends ConsumerState<SeatBoardScreen> {
  SeatBoard? _board;
  var _loading = true;
  String? _error;
  String? _conductorCode;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    try {
      final board = await ref.read(seatRepositoryProvider).seatBoard();
      if (!mounted) return;
      setState(() {
        _board = board;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is AlongException ? error.code.apiValue : 'error';
      });
    }
  }

  Future<void> _set(String seatId, String status) async {
    final board = _board;
    if (board == null) return;
    final result = await ref
        .read(seatRepositoryProvider)
        .setSeatStatus(
          layoutId: board.layoutId,
          seatId: seatId,
          status: status,
        );
    if (seatDeltaPayloadBytes(result.toJson()) > 200 && mounted) {
      setState(() => _error = 'delta');
    }
    await _load();
  }

  Future<void> _openConductor() async {
    try {
      final code = await ref
          .read(seatRepositoryProvider)
          .openConductorSession();
      if (!mounted) return;
      setState(() => _conductorCode = code);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AlongException ? error.code.apiValue : 'error';
      });
    }
  }

  Future<void> _voice(String raw, SeatBoard board) async {
    final command = parseDriverVoice(raw);
    if (command == null) return;
    if (command.intent == DriverVoiceIntent.full) {
      await ref
          .read(seatRepositoryProvider)
          .setAllSeats(layoutId: board.layoutId, status: 'occupied');
      await _load();
      return;
    }
    if (command.intent == DriverVoiceIntent.empty) {
      await ref
          .read(seatRepositoryProvider)
          .setAllSeats(layoutId: board.layoutId, status: 'free');
      await _load();
      return;
    }
    if (command.intent != DriverVoiceIntent.seat) return;
    final refName = command.seatRef?.toLowerCase();
    SeatSpec? seat;
    for (final row in board.layout.rows) {
      for (final item in row.seats) {
        if (!item.isPassenger) continue;
        if (item.id.toLowerCase() == refName ||
            item.label.toLowerCase() == refName) {
          seat = item;
        }
      }
    }
    if (seat == null || command.seatStatus == null) return;
    await _set(seat.id, command.seatStatus!);
  }

  List<String> _ghosts(SeatBoard board) {
    return ghostSeatIds(
      layout: board.layout,
      states: {
        for (final seat in board.seats)
          seat.seatId: SeatOccupancy(status: seat.status),
      },
    );
  }

  String _word(AppLocalizations l10n, String status) {
    return switch (status) {
      'occupied' => l10n.seatOccupied,
      'held' => l10n.seatHeld,
      'blocked' => l10n.seatBlocked,
      _ => l10n.seatFree,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final board = _board;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.seatMapTitle),
        backgroundColor: AlongPalette.of(context).bg,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : board == null
          ? Center(
              child: AlongButton(
                key: const Key('seat_board_build_day'),
                label: l10n.buildMyDayTitle,
                onPressed: () => context.push(AppRoutes.buildMyDay),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AlongSpace.s16),
              children: [
                Text(
                  l10n.freeSeatCount(board.freeCount),
                  style: AlongText.bodyStrong,
                ),
                if (board.seatUpdatedAt != null &&
                    seatStateIsStale(board.seatUpdatedAt!, DateTime.now()))
                  Text(
                    l10n.seatStale,
                    key: const Key('seat_stale_badge'),
                    style: AlongText.caption.copyWith(
                      color: AlongColors.semanticWarning,
                    ),
                  ),
                const SizedBox(height: AlongSpace.s12),
                SeatMap(
                  body: board.layout.body,
                  rows: [
                    for (final row in board.layout.rows)
                      SeatMapRowView(
                        id: row.id,
                        ruleTitle: _rowRule(board.rules, row.id),
                        seats: [
                          for (final seat in row.seats)
                            SeatMapSeat(
                              id: seat.id,
                              label: seat.label,
                              role: seat.role,
                              status: _status(board, seat.id),
                              statusWord: seat.isCargo
                                  ? l10n.seatLuggage
                                  : seat.isPassenger
                                  ? _word(l10n, _status(board, seat.id))
                                  : l10n.seatDriver,
                            ),
                        ],
                      ),
                  ],
                  onSeatTap: (id) {
                    final status = _status(board, id);
                    _set(id, status == 'free' ? 'occupied' : 'free');
                  },
                  onSeatLongPress: (id) => _set(id, 'held'),
                ),
                const SizedBox(height: AlongSpace.s16),
                Row(
                  children: [
                    Expanded(
                      child: AlongButton(
                        key: const Key('seat_board_empty'),
                        label: l10n.seatEmpty,
                        variant: AlongButtonVariant.secondary,
                        onPressed: () async {
                          await ref
                              .read(seatRepositoryProvider)
                              .setAllSeats(
                                layoutId: board.layoutId,
                                status: 'free',
                              );
                          await _load();
                        },
                      ),
                    ),
                    const SizedBox(width: AlongSpace.s8),
                    Expanded(
                      child: AlongButton(
                        key: const Key('seat_board_full'),
                        label: l10n.seatFull,
                        variant: AlongButtonVariant.secondary,
                        onPressed: () async {
                          await ref
                              .read(seatRepositoryProvider)
                              .setAllSeats(
                                layoutId: board.layoutId,
                                status: 'occupied',
                              );
                          await _load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlongSpace.s16),
                TextField(
                  key: const Key('seat_voice_command'),
                  decoration: InputDecoration(hintText: l10n.voiceCommandHint),
                  onSubmitted: (value) => _voice(value, board),
                ),
                const SizedBox(height: AlongSpace.s8),
                AlongButton(
                  key: const Key('seat_board_conductor'),
                  label: l10n.conductorOpen,
                  variant: AlongButtonVariant.secondary,
                  onPressed: _openConductor,
                ),
                if (_conductorCode != null)
                  Text(
                    _conductorCode!,
                    key: const Key('conductor_code'),
                    style: AlongText.numericL,
                  ),
                if (_ghosts(board).isNotEmpty) ...[
                  const SizedBox(height: AlongSpace.s12),
                  Text(l10n.ghostSeatTitle, style: AlongText.label),
                  for (final id in _ghosts(board))
                    ListTile(
                      title: Text(board.layout.seatById(id)?.label ?? id),
                      trailing: TextButton(
                        key: Key('ghost_free_$id'),
                        onPressed: () => _set(id, 'free'),
                        child: Text(l10n.ghostSeatFree),
                      ),
                    ),
                ],
                const SizedBox(height: AlongSpace.s16),
                Text(l10n.rideRulesHeading, style: AlongText.label),
                for (final rule in board.rules)
                  ListTile(
                    title: Text(rule.title),
                    subtitle: Text(rule.body ?? ''),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: AlongText.caption.copyWith(
                      color: AlongColors.semanticDanger,
                    ),
                  ),
              ],
            ),
    );
  }

  String _status(SeatBoard board, String seatId) {
    for (final seat in board.seats) {
      if (seat.seatId == seatId) return seat.status;
    }
    return 'free';
  }

  String? _rowRule(List<RideRule> rules, String rowId) {
    final titles = [
      for (final rule in rules)
        if (rule.enabled &&
            rule.targetScope == 'row' &&
            rule.targetRef == rowId)
          rule.title,
    ];
    if (titles.isEmpty) return null;
    return titles.join(' · ');
  }
}
